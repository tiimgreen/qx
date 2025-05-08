class WorkPreparationsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, except: [ :index ]
  before_action :set_work_preparation, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    base_scope = @project.work_preparations.includes(:work_location, isometry: [ :project, :sector ])

    if params[:search].present?
      base_scope = base_scope.search_by_term(params[:search])
    end

    sort_column = sort_params || "line_id"  # Default sort by line_id
    sort_direction = params[:direction] || "asc"

    # If using default sort (line_id), add secondary sorts for page_number and id
    @work_preparations = if sort_column == "line_id"
      base_scope.joins(:isometry)
               .reorder("isometries.line_id #{sort_direction}")
               .order("isometries.page_number #{sort_direction}")
               .order("isometries.id ASC")  # Always show older isometries first within same line/page
    else
      base_scope.reorder(sort_column => sort_direction)
    end

    @pagy, @work_preparations = pagy(@work_preparations)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @work_preparation }
    end
  end

  def new
    @work_preparation = @project.work_preparations.new
    if @isometry
      @work_preparation.work_package_number = @isometry.work_package_number
    end
  end

  def edit
    @isometry = @work_preparation.isometry if @work_preparation
    # Initialize weldings array for the form
    @weldings = @work_preparation.isometry.weldings.map do |welding|
      {
        id: welding.id,
        batch_number: welding.batch_number,
        batch_number1: welding.batch_number1,
        material_certificate_id: welding.material_certificate_id,
        material_certificate1_id: welding.material_certificate1_id
      }
    end
  end

  def create
    @work_preparation = @project.work_preparations.build(work_preparation_params.except(:on_hold_images))
    @work_preparation.user = current_user

    if @work_preparation.save
      update_weldings if params[:weldings].present?
      handle_docuvita_image_uploads(@work_preparation)
      redirect_to project_work_preparations_path(@project), notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @work_preparation.update(work_preparation_params.except(:on_hold_images))
      update_weldings if params[:weldings].present?
      handle_docuvita_image_uploads(@work_preparation)
      redirect_to project_work_preparations_path(@project), notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def complete
    complete_resource(
      @work_preparation,
      project_work_preparation_path(@project, @work_preparation),
      {}  # No need for params, completion values will be set by complete_resource
    )
  end

  def destroy
    @work_preparation.destroy
    redirect_to project_work_preparations_path(@project, locale: I18n.locale),
                notice: t("common.messages.success.deleted", model: WorkPreparation.model_name.human)
  end

  private

  def sort_params
    allowed_columns = %w[
      line_id work_package_number page_number
      created_at completed on_hold_status
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_work_preparation
    @work_preparation = @project.work_preparations.find(params[:id])
  end

  def set_isometry
    isometry_id = if params[:work_preparation].present?
                   params[:work_preparation][:isometry_id]
    else
                   params[:isometry_id]
    end
    @isometry = @project.isometries.find(isometry_id) if isometry_id.present?
  end

  def work_preparation_params
    params.require(:work_preparation).permit(
      :isometry_id,
      :work_location_id,
      :work_preparation_type,
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :completed,
      :total_time,
      :project_id,
      welding_batch_assignments_attributes: [
        :id,
        :welding_id,
        :batch_number,
        :batch_number1,
        :material_certificate_id,
        :material_certificate1_id,
        :_destroy
      ]
    )
  end

  def update_weldings
    params[:weldings].each do |welding_params|
      welding = @isometry.weldings.find(welding_params[:id])
      update_params = {
        batch_number: welding_params[:batch_number],
        batch_number1: welding_params[:batch_number1],
        material_certificate_id: welding_params[:batch_number].blank? ? nil : welding_params[:material_certificate_id],
        material_certificate1_id: welding_params[:batch_number1].blank? ? nil : welding_params[:material_certificate1_id]
      }
      welding.update(update_params)
    end
  end

  def handle_docuvita_image_uploads(work_preparation)
    # Handle on-hold images from the raw params, not the filtered params
    if params.dig(:work_preparation, :on_hold_images).present?
      Array(params[:work_preparation][:on_hold_images]).each do |image|
        next unless image.is_a?(ActionDispatch::Http::UploadedFile)
        work_preparation.upload_image_to_docuvita(image, image.original_filename, "on_hold_image")
      end
    end
  end

  def authorize_action!
    case action_name
    when "index", "show"
      authorize_view!
    when "new", "create"
      authorize_create!
    when "edit", "update"
      authorize_edit!
    when "destroy"
      authorize_destroy!
    end
  end

  def authorize_view!
    unless current_user.can_view?("WorkPreparation")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: WorkPreparation.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("WorkPreparation")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: WorkPreparation.model_name.human)
      redirect_to request.referer || project_work_preparations_path(@project)
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("WorkPreparation")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: WorkPreparation.model_name.human)
      redirect_to request.referer || work_preparation_path(@work_preparation)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("WorkPreparation")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: WorkPreparation.model_name.human)
      redirect_to request.referer || work_preparation_path(@work_preparation)
    end
  end
end
