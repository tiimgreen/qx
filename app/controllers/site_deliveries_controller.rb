class SiteDeliveriesController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, except: [ :index ]
  before_action :set_site_delivery, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    base_scope = @project.site_deliveries.includes(isometry: [ :project, :sector ])

    if params[:search].present?
      base_scope = base_scope.search_by_term(params[:search])
    end

    sort_column = sort_params || "line_id"  # Default sort by line_id
    sort_direction = params[:direction] || "asc"

    # If using default sort (line_id), add secondary sorts for page_number and id
    @site_deliveries = if sort_column == "line_id"
      base_scope.joins(:isometry)
               .reorder("isometries.line_id #{sort_direction}")
               .order("isometries.page_number #{sort_direction}")
               .order("isometries.id ASC")  # Always show older isometries first within same line/page
    else
      base_scope.reorder(sort_column => sort_direction)
    end

    @pagy, @site_deliveries = pagy(@site_deliveries)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @site_delivery }
    end
  end

  def new
    @site_delivery = @project.site_deliveries.new
    if @isometry
      @site_delivery.work_package_number = @isometry.work_package_number
    end
  end

  def edit
    @isometry = @site_delivery.isometry
  end

  def create
    @site_delivery = @project.site_deliveries.new(site_delivery_params.except(:check_spools_images))
    @site_delivery.user = current_user

    if @site_delivery.save
      handle_docuvita_image_uploads(@site_delivery)
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
    check_spool_params(params)

    if @site_delivery.update(site_delivery_params.except(:check_spools_images))
      handle_docuvita_image_uploads(@site_delivery)
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
      {}
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
      line_id work_package_number page_number
      created_at completed check_spools_status
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_isometry
    @isometry = @project.isometries.find(params[:site_delivery][:isometry_id]) if params[:site_delivery].present?
  end

  def set_site_delivery
    @site_delivery = @project.site_deliveries.find(params[:id])
  end

  def site_delivery_params
    return {} unless params[:site_delivery].present?

    params.require(:site_delivery).permit(
      :work_package_number,
      :check_spools_status,
      :check_spools_comment,
      :completed,
      :isometry_id,
      :total_time,
      check_spools_images: []
    )
  end

  def handle_docuvita_image_uploads(site_delivery)
    if params.dig(:site_delivery, :check_spools_images).present?
      Array(params[:site_delivery][:check_spools_images]).each do |image|
        next unless image.is_a?(ActionDispatch::Http::UploadedFile)
        site_delivery.upload_image_to_docuvita(image, image.original_filename, "check_spools_image")
      end
    end
  end

  def check_spool_params(params)
    if params[:site_delivery][:check_spools_status] == "Failed"
      params[:site_delivery][:completed] = nil
    else
      params[:site_delivery][:check_spools_comment] = nil
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
      redirect_to request.referer || project_site_deliveries_path(@project)
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
