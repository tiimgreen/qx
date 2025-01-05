class SiteDeliveriesController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_site_delivery, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    sort_column = sort_params || "created_at"
    sort_direction = params[:direction] || "desc"

    @pagy, @site_deliveries = pagy(
      @project.site_deliveries.search_by_term(params[:search])
            .order(sort_column => sort_direction)
    )
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @site_delivery }
    end
  end

  def new
    @site_delivery = @project.site_deliveries.new
  end

  def edit
  end

  def create
    @site_delivery = @project.site_deliveries.new(site_delivery_params_without_images)
    @site_delivery.user = current_user

    # Handle image attachments separately
    attach_on_hold_images if params.dig(:site_delivery, :on_hold_images).present?

    if @site_delivery.save
      redirect_to project_site_delivery_path(@project, @site_delivery),
                  notice: t("common.messages.success.created", model: SiteDelivery.model_name.human)
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "site_delivery_form",
            partial: "form",
            locals: { project: @project, site_delivery: @site_delivery }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)
    attach_on_hold_images if params.dig(:site_delivery, :on_hold_images).present?

    if @site_delivery.update(site_delivery_params_without_images)
      redirect_to project_site_delivery_path(@project, @site_delivery),
                  notice: t("common.messages.success.updated", model: SiteDelivery.model_name.human)
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "site_delivery_form",
            partial: "form",
            locals: { project: @project, site_delivery: @site_delivery }
          )
        }
      end
    end
  end

  def complete
    complete_resource(
      @site_delivery,
      project_site_delivery_path(@project, @site_delivery),
      {}  # No need for params, completion values will be set by complete_resource
    )
  end

  def destroy
    @site_delivery.destroy
    redirect_to project_site_deliveries_path(@project, locale: I18n.locale),
                notice: t("common.messages.success.deleted", model: SiteDelivery.model_name.human)
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

  def set_site_delivery
    @site_delivery = @project.site_deliveries.find(params[:id])
  end

  def site_delivery_params
    return {} unless params[:site_delivery].present?

    params.require(:site_delivery).permit(
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :completed,
      :total_time,
      on_hold_images: []
    )
  end

  def site_delivery_params_without_images
    site_delivery_params.except(:on_hold_images)
  end

  def attach_on_hold_images
    return unless params.dig(:site_delivery, :on_hold_images).present?

    params[:site_delivery][:on_hold_images].each do |image|
      @site_delivery.on_hold_images.attach(image)
    end
  end

  def on_hold_params(params)
    if params[:site_delivery][:on_hold_status] == "On Hold"
      params[:site_delivery][:on_hold_date] = Time.current
      params[:site_delivery][:completed] = nil
    else
      params[:site_delivery][:on_hold_date] = nil
      params[:site_delivery][:on_hold_comment] = nil
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
    unless current_user.can_view?("SiteDelivery")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: SiteDelivery.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("SiteDelivery")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: SiteDelivery.model_name.human)
      redirect_to request.referer || site_deliveries_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("SiteDelivery")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: SiteDelivery.model_name.human)
      redirect_to request.referer || site_delivery_path(@site_delivery)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("SiteDelivery")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: SiteDelivery.model_name.human)
      redirect_to request.referer || site_delivery_path(@site_delivery)
    end
  end
end
