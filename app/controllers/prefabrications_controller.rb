class PrefabricationsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, except: [ :index ]
  before_action :set_prefabrication, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    base_scope = @project.prefabrications.includes(:work_location, isometry: [ :project, :sector ])

    if params[:search].present?
      base_scope = base_scope.search_by_term(params[:search])
    end

    sort_column = sort_params || "line_id"  # Default sort by line_id
    sort_direction = params[:direction] || "asc"

    # If using default sort (line_id), add secondary sorts for page_number and id
    @prefabrications = if sort_column == "line_id"
      base_scope.joins(:isometry)
               .reorder("isometries.line_id #{sort_direction}")
               .order("isometries.page_number #{sort_direction}")
               .order("isometries.id ASC")  # Always show older isometries first within same line/page
    else
      base_scope.reorder(sort_column => sort_direction)
    end

    @pagy, @prefabrications = pagy(@prefabrications)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @prefabrication }
    end
  end

  def new
    @prefabrication = @project.prefabrications.new
    if @isometry
      @prefabrication.work_package_number = @isometry.work_package_number
    end
  end

  def edit
    @isometry = @prefabrication.isometry
  end

  def create
    @prefabrication = @project.prefabrications.build(prefabrication_params.except(:on_hold_images))
    @prefabrication.user = current_user
    @prefabrication.active = true

    if @prefabrication.save
      handle_docuvita_image_uploads(@prefabrication)
      redirect_to project_prefabrication_path(@project, @prefabrication),
                  notice: t("common.messages.success.created", model: Prefabrication.model_name.human)
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "prefabrication_form",
            partial: "form",
            locals: { project: @project, prefabrication: @prefabrication }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)

    if @prefabrication.update(prefabrication_params.except(:on_hold_images))
      handle_docuvita_image_uploads(@prefabrication)
      redirect_to project_prefabrication_path(@project, @prefabrication),
                  notice: t("common.messages.success.updated", model: Prefabrication.model_name.human)
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "prefabrication_form",
            partial: "form",
            locals: { project: @project, prefabrication: @prefabrication }
          )
        }
      end
    end
  end

  def complete
    complete_resource(
      @prefabrication,
      project_prefabrication_path(@project, @prefabrication),
      {}  # No need for params, completion values will be set by complete_resource
    )
  end

  def destroy
    @prefabrication.destroy
    redirect_to project_prefabrications_path(@project, locale: I18n.locale),
                notice: t("common.messages.success.deleted", model: Prefabrication.model_name.human)
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

  def set_prefabrication
    @prefabrication = @project.prefabrications.find(params[:id])
  end

  def set_isometry
    if params[:prefabrication].present? && params[:prefabrication][:isometry_id].present?
      @isometry = @project.isometries.find(params[:prefabrication][:isometry_id])
    end
  end

  def prefabrication_params
    return {} unless params[:prefabrication].present?

    params.require(:prefabrication).permit(
      :work_location_id,
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :active,
      :completed,
      :isometry_id,
      :total_time,
      on_hold_images: []
    )
  end

  def handle_docuvita_image_uploads(prefabrication)
    if params.dig(:prefabrication, :on_hold_images).present?
      Array(params[:prefabrication][:on_hold_images]).each do |image|
        next unless image.is_a?(ActionDispatch::Http::UploadedFile)
        if image.content_type == "application/pdf"
          prefabrication.upload_pdf_to_docuvita(image, image.original_filename, "on_hold_image", "prefabrication")
        else
          prefabrication.upload_image_to_docuvita(image, image.original_filename, "on_hold_image", "prefabrication")
        end
      end
    end
  end

  def on_hold_params(params)
    if params[:prefabrication][:on_hold_status] == "On Hold"
      params[:prefabrication][:on_hold_date] = Time.current
      params[:prefabrication][:completed] = nil
      params[:prefabrication][:active] = true
    else
      params[:prefabrication][:on_hold_date] = nil
      params[:prefabrication][:active] = false
      params[:prefabrication][:on_hold_comment] = nil
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
    unless current_user.can_view?("Prefabrication")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: Prefabrication.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("Prefabrication")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: Prefabrication.model_name.human)
      redirect_to request.referer || prefabrications_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("Prefabrication")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: Prefabrication.model_name.human)
      redirect_to request.referer || prefabrication_path(@prefabrication)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("Prefabrication")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: Prefabrication.model_name.human)
      redirect_to request.referer || prefabrication_path(@prefabrication)
    end
  end
end
