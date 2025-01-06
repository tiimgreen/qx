class PreWeldingsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_pre_welding, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    sort_column = sort_params || "created_at"
    sort_direction = params[:direction] || "desc"

    @pagy, @pre_weldings = pagy(
      @project.pre_weldings.includes(:work_location).search_by_term(params[:search])
            .order(sort_column => sort_direction)
    )
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @pre_welding }
    end
  end

  def new
    @pre_welding = @project.pre_weldings.new
  end

  def edit
  end

  def create
    @pre_welding = @project.pre_weldings.new(pre_welding_params_without_images)
    @pre_welding.user = current_user

    # Handle image attachments separately
    attach_on_hold_images if params.dig(:pre_welding, :on_hold_images).present?

    if @pre_welding.save
      redirect_to project_pre_welding_path(@project, @pre_welding),
                  notice: t("common.messages.success.created", model: PreWelding.model_name.human)
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "pre_welding_form",
            partial: "form",
            locals: { project: @project, pre_welding: @pre_welding }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)
    attach_on_hold_images if params.dig(:pre_welding, :on_hold_images).present?

    if @pre_welding.update(pre_welding_params_without_images)
      redirect_to project_pre_welding_path(@project, @pre_welding),
                  notice: t("common.messages.success.updated", model: PreWelding.model_name.human)
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "pre_welding_form",
            partial: "form",
            locals: { project: @project, pre_welding: @pre_welding }
          )
        }
      end
    end
  end

  def complete
    complete_resource(
      @pre_welding,
      project_pre_welding_path(@project, @pre_welding),
      {}  # No need for params, completion values will be set by complete_resource
    )
  end

  def destroy
    @pre_welding.destroy
    redirect_to project_pre_weldings_path(@project, locale: I18n.locale),
                notice: t("common.messages.success.deleted", model: PreWelding.model_name.human)
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

  def set_pre_welding
    @pre_welding = @project.pre_weldings.find(params[:id])
  end

  def pre_welding_params
    return {} unless params[:pre_welding].present?

    params.require(:pre_welding).permit(
      :work_location_id,
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :completed,
      :total_time,
      on_hold_images: []
    )
  end

  def pre_welding_params_without_images
    pre_welding_params.except(:on_hold_images)
  end

  def attach_on_hold_images
    return unless params.dig(:pre_welding, :on_hold_images).present?

    params[:pre_welding][:on_hold_images].each do |image|
      @pre_welding.on_hold_images.attach(image)
    end
  end

  def on_hold_params(params)
    if params[:pre_welding][:on_hold_status] == "On Hold"
      params[:pre_welding][:on_hold_date] = Time.current
      params[:pre_welding][:completed] = nil
      params[:pre_welding][:active] = true
    else
      params[:pre_welding][:on_hold_date] = nil
      params[:pre_welding][:active] = false
      params[:pre_welding][:on_hold_comment] = nil
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
    unless current_user.can_view?("PreWelding")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: PreWelding.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("PreWelding")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: PreWelding.model_name.human)
      redirect_to request.referer || pre_weldings_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("PreWelding")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: PreWelding.model_name.human)
      redirect_to request.referer || pre_welding_path(@pre_welding)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("PreWelding")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: PreWelding.model_name.human)
      redirect_to request.referer || pre_welding_path(@pre_welding)
    end
  end
end
