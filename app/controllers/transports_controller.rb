class TransportsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, except: [ :index ]
  before_action :set_transport, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    base_scope = @project.transports.includes(isometry: [ :project, :sector ])

    if params[:search].present?
      base_scope = base_scope.search_by_term(params[:search])
    end

    sort_column = sort_params || "line_id"  # Default sort by line_id
    sort_direction = params[:direction] || "asc"

    # If using default sort (line_id), add secondary sorts for page_number and id
    @transports = if sort_column == "line_id"
      base_scope.joins(:isometry)
               .reorder("isometries.line_id #{sort_direction}")
               .order("isometries.page_number #{sort_direction}")
               .order("isometries.id ASC")  # Always show older isometries first within same line/page
    else
      base_scope.reorder(sort_column => sort_direction)
    end

    @pagy, @transports = pagy(@transports)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @transport }
    end
  end

  def new
    @transport = @project.transports.new
    if @isometry
      @transport.work_package_number = @isometry.work_package_number
    end
  end

  def edit
    @isometry = @transport.isometry
  end

  def create
    @transport = @project.transports.new(transport_params_without_images)
    @transport.user = current_user

    attach_check_spools_images if params.dig(:transport, :check_spools_images).present?

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
    check_spools_params(params)
    attach_check_spools_images if params.dig(:transport, :check_spools_images).present?

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
      {}
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
      line_id work_package_number page_number
      created_at completed check_spools_status
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_transport
    @transport = @project.transports.find(params[:id])
  end

  def set_isometry
    if params[:transport].present? && params[:transport][:isometry_id].present?
      @isometry = @project.isometries.find(params[:transport][:isometry_id])
    end
  end

  def transport_params
    return {} unless params[:transport].present?

    params.require(:transport).permit(
      :work_package_number,
      :check_spools_status,
      :check_spools_comment,
      :completed,
      :total_time,
      :isometry_id,
      check_spools_images: []
    )
  end

  def transport_params_without_images
    transport_params.except(:check_spools_images)
  end

  def attach_check_spools_images
    return unless params.dig(:transport, :check_spools_images).present?

    params[:transport][:check_spools_images].each do |image|
      @transport.check_spools_images.attach(image)
    end
  end

  def check_spools_params(params)
    if params[:transport][:check_spools_status] == "Failed"
      params[:transport][:completed] = nil
    else
      params[:transport][:check_spools_comment] = nil
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
      redirect_to request.referer || project_transports_path(@project)
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
