class ProjectsController < ApplicationController
  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :material_certificates ]
  before_action :authorize_action!

  def index
    sort_column    = sort_params || "created_at"
    sort_direction = params[:direction] || "desc"

    projects_scope = Project.search_by_term(params[:search])

    if params.key?(:archived)
      archived_flag = ActiveModel::Type::Boolean.new.cast(params[:archived])
      projects_scope = archived_flag ? projects_scope.archived : projects_scope.active
    else
      projects_scope = projects_scope.active
    end

    @pagy, @projects = pagy(
      projects_scope.order(sort_column => sort_direction)
    )
  end

  def show
    @sectors = Sector.where.not(id: Sector.find_by(key: :project).id)
  end

  # Displays a table of each isometry in the project and its related material certificates
  def material_certificates
    @isometries = @project.isometries
                              .includes(:material_certificates)
                              .left_outer_joins(:material_certificates)

    if params[:search].present?
      term = "%#{params[:search].strip.downcase}%"
      @isometries = @isometries.where(
        "LOWER(isometries.line_id) LIKE :term OR LOWER(material_certificates.certificate_number) LIKE :term OR LOWER(material_certificates.batch_number) LIKE :term",
        term: term
      )
    end

    @isometries = @isometries.distinct.order(:line_id)
  end

  def new
    @project = Project.new
    # Set default Isometry sector
    @project.sollist_filter1_sector = Sector.find_by(key: :isometry)
  end

  def edit
    # Ensure workshop checkbox state matches project sectors
    @project.workshop = @project.sectors.exists?
  end

  def create
    @project = Project.new(project_params)
    @project.user = current_user

    if @project.save
      handle_sector_associations
      redirect_to @project, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
      handle_sector_associations
      redirect_to @project, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_url, notice: "Project was successfully deleted."
  end

  private

  def handle_sector_associations
    # When a project is archived we freeze its relations. Skip association
    # rewriting in that case to avoid destroy-attempts that the
    # LockedByArchivedProject concern rightfully prevents.
    return if @project.archived?
    return unless params[:project][:sector_ids]
    # Clear existing associations and create new ones
    @project.project_sectors.destroy_all
    sector_ids = params[:project][:sector_ids].reject(&:blank?)
    sector_ids.each do |sector_id|
      @project.project_sectors.create(sector_id: sector_id)
    end
  end

  def sort_params
    allowed_columns = %w[
      project_number
      name
      description
      project_manager
      client_name
      created_at
      project_end
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    project_id = params[:id] || params[:project_id]
    @project = Project.find(project_id)
  end

  def project_params
    params.require(:project).permit(
      :project_number, :name, :description,
      :project_manager_client, :project_manager_qualinox,
      :client_name, :project_start, :project_end,
      :workshop, :archived,
      :sollist_filter1_sector_id, :sollist_filter2_sector_id, :sollist_filter3_sector_id,
      :progress_filter1_sector_id, :progress_filter2_sector_id,
      sector_ids: []
    )
  end

  def authorize_action!
    case action_name
    when "index", "show", "material_certificates"
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
    unless current_user.can_view?("Project")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: Project.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("Project")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: Project.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("Project")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: Project.model_name.human)
      redirect_to request.referer || project_path(@project)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("Project")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: Project.model_name.human)
      redirect_to request.referer || project_path(@project)
    end
  end
end
