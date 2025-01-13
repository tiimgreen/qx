class SiteAssembliesController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, except: [ :index ]
  before_action :set_site_assembly, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    sort_column = sort_params || "created_at"
    sort_direction = params[:direction] || "desc"

    @pagy, @site_assemblies = pagy(
      @project.site_assemblies.search_by_term(params[:search])
            .order(sort_column => sort_direction)
    )
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @site_assembly }
    end
  end

  def new
    @site_assembly = @project.site_assemblies.new
    if @isometry
      @site_assembly.work_package_number = @isometry.work_package_number
    end
  end

  def edit
    @isometry = @site_assembly.isometry
  end

  def create
    @site_assembly = @project.site_assemblies.new(site_assembly_params_without_images)
    @site_assembly.user = current_user

    # Handle image attachments separately
    attach_on_hold_images if params.dig(:site_assembly, :on_hold_images).present?

    if @site_assembly.save
      redirect_to project_site_assembly_path(@project, @site_assembly),
                  notice: t("common.messages.success.created", model: SiteAssembly.model_name.human)
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "site_assembly_form",
            partial: "form",
            locals: { project: @project, site_assembly: @site_assembly }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)
    attach_on_hold_images if params.dig(:site_assembly, :on_hold_images).present?

    if @site_assembly.update(site_assembly_params_without_images)
      redirect_to project_site_assembly_path(@project, @site_assembly),
                  notice: t("common.messages.success.updated", model: SiteAssembly.model_name.human)
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "site_assembly_form",
            partial: "form",
            locals: { project: @project, site_assembly: @site_assembly }
          )
        }
      end
    end
  end

  def complete
    complete_resource(
      @site_assembly,
      project_site_assembly_path(@project, @site_assembly),
      {}  # No need for params, completion values will be set by complete_resource
    )
  end

  def destroy
    @site_assembly.destroy
    redirect_to project_site_assemblies_path(@project, locale: I18n.locale),
                notice: t("common.messages.success.deleted", model: SiteAssembly.model_name.human)
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

  def set_site_assembly
    @site_assembly = @project.site_assemblies.find(params[:id])
  end

  def set_isometry
    if params[:site_assembly].present? && params[:site_assembly][:isometry_id].present?
      @isometry = @project.isometries.find(params[:site_assembly][:isometry_id])
    end
  end

  def site_assembly_params
    return {} unless params[:site_assembly].present?

    params.require(:site_assembly).permit(
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :completed,
      :isometry_id,
      :total_time,
      on_hold_images: []
    )
  end

  def site_assembly_params_without_images
    site_assembly_params.except(:on_hold_images)
  end

  def attach_on_hold_images
    return unless params.dig(:site_assembly, :on_hold_images).present?

    params[:site_assembly][:on_hold_images].each do |image|
      @site_assembly.on_hold_images.attach(image)
    end
  end

  def on_hold_params(params)
    if params[:site_assembly][:on_hold_status] == "On Hold"
      params[:site_assembly][:on_hold_date] = Time.current
      params[:site_assembly][:completed] = nil
    else
      params[:site_assembly][:on_hold_date] = nil
      params[:site_assembly][:on_hold_comment] = nil
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
    unless current_user.can_view?("SiteAssembly")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: SiteAssembly.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("SiteAssembly")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: SiteAssembly.model_name.human)
      redirect_to request.referer || site_assemblies_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("SiteAssembly")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: SiteAssembly.model_name.human)
      redirect_to request.referer || site_assembly_path(@site_assembly)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("SiteAssembly")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: SiteAssembly.model_name.human)
      redirect_to request.referer || site_assembly_path(@site_assembly)
    end
  end
end
