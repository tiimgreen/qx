class FinalInspectionsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, except: [ :index ]
  before_action :set_final_inspection, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    base_scope = @project.final_inspections.includes(:work_location, isometry: [ :project, :sector ])

    if params[:search].present?
      base_scope = base_scope.search_by_term(params[:search])
    end

    sort_column = sort_params || "line_id"  # Default sort by line_id
    sort_direction = params[:direction] || "asc"

    # If using default sort (line_id), add secondary sorts for page_number and id
    @final_inspections = if sort_column == "line_id"
      base_scope.joins(:isometry)
               .reorder("isometries.line_id #{sort_direction}")
               .order("isometries.page_number #{sort_direction}")
               .order("isometries.id ASC")  # Always show older isometries first within same line/page
    else
      base_scope.reorder(sort_column => sort_direction)
    end

    @pagy, @final_inspections = pagy(@final_inspections)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @final_inspection }
    end
  end

  def new
    @final_inspection = @project.final_inspections.new
    if @isometry
      @final_inspection.work_package_number = @isometry.work_package_number
    end
  end

  def edit
    @isometry = @final_inspection.isometry
  end

  def create
    @final_inspection = @project.final_inspections.new(final_inspection_params_without_images)
    @final_inspection.user = current_user

    # Handle image attachments separately
    attach_images(:on_hold_images) if params.dig(:final_inspection, :on_hold_images).present?
    attach_images(:visual_check_images) if params.dig(:final_inspection, :visual_check_images).present?
    attach_images(:vt2_check_images) if params.dig(:final_inspection, :vt2_check_images).present?
    attach_images(:pt2_check_images) if params.dig(:final_inspection, :pt2_check_images).present?
    attach_images(:rt_check_images) if params.dig(:final_inspection, :rt_check_images).present?

    if @final_inspection.save
      redirect_to project_final_inspection_path(@project, @final_inspection),
                  notice: t("common.messages.success.created", model: FinalInspection.model_name.human)
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "final_inspection_form",
            partial: "form",
            locals: { project: @project, final_inspection: @final_inspection }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)
    attach_images(:on_hold_images) if params.dig(:final_inspection, :on_hold_images).present?
    attach_images(:visual_check_images) if params.dig(:final_inspection, :visual_check_images).present?
    attach_images(:vt2_check_images) if params.dig(:final_inspection, :vt2_check_images).present?
    attach_images(:pt2_check_images) if params.dig(:final_inspection, :pt2_check_images).present?
    attach_images(:rt_check_images) if params.dig(:final_inspection, :rt_check_images).present?

    if @final_inspection.update(final_inspection_params_without_images)
      redirect_to project_final_inspection_path(@project, @final_inspection),
                  notice: t("common.messages.success.updated", model: FinalInspection.model_name.human)
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "final_inspection_form",
            partial: "form",
            locals: { project: @project, final_inspection: @final_inspection }
          )
        }
      end
    end
  end

  def complete
    complete_resource(
      @final_inspection,
      project_final_inspection_path(@project, @final_inspection),
      {}
    )
  end

  def destroy
    @final_inspection.destroy
    redirect_to project_final_inspections_path(@project, locale: I18n.locale),
                notice: t("common.messages.success.deleted", model: FinalInspection.model_name.human)
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

  def set_final_inspection
    @final_inspection = @project.final_inspections.find(params[:id])
  end

  def set_isometry
    if params[:final_inspection].present? && params[:final_inspection][:isometry_id].present?
      @isometry = @project.isometries.find(params[:final_inspection][:isometry_id])
    end
  end

  def final_inspection_params
    return {} unless params[:final_inspection].present?

    params.require(:final_inspection).permit(
      :work_location_id,
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :visual_check_status,
      :visual_check_comment,
      :vt2_check_status,
      :vt2_check_comment,
      :pt2_check_status,
      :pt2_check_comment,
      :rt_check_status,
      :rt_check_comment,
      :completed,
      :total_time,
      :project_id,
      :isometry_id,
      on_hold_images: [],
      visual_check_images: [],
      vt2_check_images: [],
      pt2_check_images: [],
      rt_check_images: []
    )
  end

  def final_inspection_params_without_images
    final_inspection_params.except(:on_hold_images, :visual_check_images, :vt2_check_images, :pt2_check_images, :rt_check_images)
  end

  def attach_images(image_type)
    return unless params.dig(:final_inspection, image_type).present?

    params[:final_inspection][image_type].each do |image|
      @final_inspection.send(image_type).attach(image)
    end
  end

  def on_hold_params(params)
    if params[:final_inspection][:on_hold_status] == "On Hold"
      params[:final_inspection][:on_hold_date] = Time.current
      params[:final_inspection][:completed] = nil
    else
      params[:final_inspection][:on_hold_date] = nil
      params[:final_inspection][:on_hold_comment] = nil
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
    unless current_user.can_view?("FinalInspection")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: FinalInspection.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("FinalInspection")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: FinalInspection.model_name.human)
      redirect_to request.referer || final_inspections_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("FinalInspection")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: FinalInspection.model_name.human)
      redirect_to request.referer || final_inspection_path(@final_inspection)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("FinalInspection")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: FinalInspection.model_name.human)
      redirect_to request.referer || final_inspection_path(@final_inspection)
    end
  end
end
