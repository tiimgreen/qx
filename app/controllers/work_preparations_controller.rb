class WorkPreparationsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_work_preparation, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    sort_column = sort_params || "created_at"
    sort_direction = params[:direction] || "desc"

    @pagy, @work_preparations = pagy(
      @project.work_preparations.includes(:work_location).search_by_term(params[:search])
            .order(sort_column => sort_direction)
    )
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @work_preparation }
    end
  end

  def new
    @work_preparation = @project.work_preparations.new
  end

  def edit
  end

  def create
    @work_preparation = @project.work_preparations.new(work_preparation_params_without_images)
    @work_preparation.user = current_user

    # Handle image attachments separately
    attach_images(:on_hold_images) if params.dig(:work_preparation, :on_hold_images).present?

    if @work_preparation.save
      redirect_to project_work_preparation_path(@project, @work_preparation),
                  notice: t("common.messages.success.created", model: WorkPreparation.model_name.human)
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "work_preparation_form",
            partial: "form",
            locals: { project: @project, work_preparation: @work_preparation }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)
    attach_images(:on_hold_images) if params.dig(:work_preparation, :on_hold_images).present?

    if @work_preparation.update(work_preparation_params_without_images)
      redirect_to project_work_preparation_path(@project, @work_preparation),
                  notice: t("common.messages.success.updated", model: WorkPreparation.model_name.human)
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "work_preparation_form",
            partial: "form",
            locals: { project: @project, work_preparation: @work_preparation }
          )
        }
      end
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

  def set_work_preparation
    @work_preparation = @project.work_preparations.find(params[:id])
  end

  def work_preparation_params
    return {} unless params[:work_preparation].present?

    params.require(:work_preparation).permit(
      :work_location_id,
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :batch_number,
      :work_preparation_type,
      :completed,
      :total_time,
      :project_id,
      on_hold_images: []
    )
  end

  def work_preparation_params_without_images
    work_preparation_params.except(:on_hold_images)
  end

  def attach_images(image_type)
    return unless params.dig(:work_preparation, image_type).present?

    params[:work_preparation][image_type].each do |image|
      @work_preparation.send(image_type).attach(image)
    end
  end

  def on_hold_params(params)
    if params[:work_preparation][:on_hold_status] == "On Hold"
      params[:work_preparation][:on_hold_date] = Time.current
      params[:work_preparation][:completed] = nil
    else
      params[:work_preparation][:on_hold_date] = nil
      params[:work_preparation][:on_hold_comment] = nil
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
      redirect_to request.referer || work_preparations_path
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
