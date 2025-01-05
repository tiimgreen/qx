class TransportsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_transport, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    sort_column = sort_params || "created_at"
    sort_direction = params[:direction] || "desc"

    @pagy, @transports = pagy(
      @project.transports.search_by_term(params[:search])
            .order(sort_column => sort_direction)
    )
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @transport }
    end
  end

  def new
    @transport = @project.transports.new
  end

  def edit
  end

  def create
    @transport = @project.transports.new(transport_params_without_images)
    @transport.user = current_user

    # Handle image attachments separately
    attach_on_hold_images if params.dig(:transport, :on_hold_images).present?

    if @transport.save
      redirect_to project_transport_path(@project, @transport),
                  notice: t("common.messages.success.created", model: Transport.model_name.human)
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "transport_form",
            partial: "form",
            locals: { project: @project, transport: @transport }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)
    attach_on_hold_images if params.dig(:transport, :on_hold_images).present?

    if @transport.update(transport_params_without_images)
      redirect_to project_transport_path(@project, @transport),
                  notice: t("common.messages.success.updated", model: Transport.model_name.human)
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "transport_form",
            partial: "form",
            locals: { project: @project, transport: @transport }
          )
        }
      end
    end
  end

  def complete
    complete_resource(
      @transport,
      project_transport_path(@project, @transport),
      {}  # No need for params, completion values will be set by complete_resource
    )
  end

  def destroy
    @transport.destroy
    redirect_to project_transports_path(@project, locale: I18n.locale),
                notice: t("common.messages.success.deleted", model: Transport.model_name.human)
  end

  private
  def sort_params
    allowed_columns = %w[
      work_package_number
      on_hold_status
      completed
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_transport
    @transport = @project.transports.find(params[:id])
  end

  def transport_params
    return {} unless params[:transport].present?

    params.require(:transport).permit(
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :completed,
      :total_time,
      on_hold_images: []
    )
  end

  def transport_params_without_images
    transport_params.except(:on_hold_images)
  end

  def attach_on_hold_images
    return unless params.dig(:transport, :on_hold_images).present?

    params[:transport][:on_hold_images].each do |image|
      @transport.on_hold_images.attach(image)
    end
  end

  def on_hold_params(params)
    if params[:transport][:on_hold_status] == "On Hold"
      params[:transport][:on_hold_date] = Time.current
      params[:transport][:completed] = nil
    else
      params[:transport][:on_hold_date] = nil
      params[:transport][:on_hold_comment] = nil
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
    unless current_user.can_view?("Transport")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: Transport.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("Transport")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: Transport.model_name.human)
      redirect_to request.referer || transports_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("Transport")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: Transport.model_name.human)
      redirect_to request.referer || transport_path(@transport)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("Transport")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: Transport.model_name.human)
      redirect_to request.referer || transport_path(@transport)
    end
  end
end
