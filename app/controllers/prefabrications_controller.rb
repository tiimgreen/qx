class PrefabricationsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_prefabrication, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    sort_column = sort_params || "created_at"
    sort_direction = params[:direction] || "desc"

    @pagy, @prefabrications = pagy(
      @project.prefabrications.includes(:work_location).search_by_term(params[:search])
            .order(sort_column => sort_direction)
    )
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @prefabrication }
    end
  end

  def new
    @prefabrication = @project.prefabrications.new
  end

  def edit
  end

  def create
    @prefabrication = @project.prefabrications.new(prefabrication_params_without_images)
    @prefabrication.user = current_user
    @prefabrication.active = true

    # Handle image attachments separately
    attach_on_hold_images if params.dig(:prefabrication, :on_hold_images).present?

    if @prefabrication.save
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
    attach_on_hold_images if params.dig(:prefabrication, :on_hold_images).present?

    if @prefabrication.update(prefabrication_params_without_images)
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
      work_package_number
      work_location_id
      on_hold_status
      completed
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_prefabrication
    @prefabrication = @project.prefabrications.find(params[:id])
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
      :total_time,
      on_hold_images: []
    )
  end

  def prefabrication_params_without_images
    prefabrication_params.except(:on_hold_images)
  end

  def attach_on_hold_images
    return unless params.dig(:prefabrication, :on_hold_images).present?

    params[:prefabrication][:on_hold_images].each do |image|
      @prefabrication.on_hold_images.attach(image)
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
