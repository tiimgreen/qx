class SiteAssembliesController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, except: [ :index ]
  before_action :set_site_assembly, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    base_scope = @project.site_assemblies.includes(isometry: [ :project, :sector ])

    if params[:search].present?
      base_scope = base_scope.search_by_term(params[:search])
    end

    sort_column = sort_params || "line_id"  # Default sort by line_id
    sort_direction = params[:direction] || "asc"

    # If using default sort (line_id), add secondary sorts for page_number and id
    @site_assemblies = if sort_column == "line_id"
      base_scope.joins(:isometry)
               .reorder("isometries.line_id #{sort_direction}")
               .order("isometries.page_number #{sort_direction}")
               .order("isometries.id ASC")  # Always show older isometries first within same line/page
    else
      base_scope.reorder(sort_column => sort_direction)
    end

    @pagy, @site_assemblies = pagy(@site_assemblies)
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

    if @site_assembly.save
      handle_docuvita_image_uploads(@site_assembly)
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

    if @site_assembly.update(site_assembly_params_without_images)
      handle_docuvita_image_uploads(@site_assembly)
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
      line_id work_package_number page_number
      created_at completed on_hold_status
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

  def handle_docuvita_image_uploads(site_assembly)
    # Handle on-hold images from the raw params, not the filtered params
    if params.dig(:site_assembly, :on_hold_images).present?
      Array(params[:site_assembly][:on_hold_images]).each do |image|
        next unless image.is_a?(ActionDispatch::Http::UploadedFile)
        if image.content_type == "application/pdf"
          site_assembly.upload_pdf_to_docuvita(image, image.original_filename, "on_hold_image", "site_assembly")
        else
          site_assembly.upload_image_to_docuvita(image, image.original_filename, "on_hold_image", "site_assembly")
        end
      end
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
