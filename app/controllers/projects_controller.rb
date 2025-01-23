class ProjectsController < ApplicationController
  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_action!

  def index
    sort_column = sort_params || "created_at"
    sort_direction = params[:direction] || "desc"

    @pagy, @projects = pagy(
      Project.search_by_term(params[:search])
            .order(sort_column => sort_direction)
    )
  end

  def show
    @sectors = Sector.where.not(id: Sector.find_by(key: :project).id)
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = Project.new(project_params)
    @project.user = current_user

    if @project.save
      redirect_to @project, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
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

  def sort_params
    allowed_columns = %w[
      project_number
      name
      description
      project_manager
      client_name
      created_at
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:project_number, :name, :description, :client_name, :id, :locale, :project_manager_client, :project_manager_qualinox, :project_end)
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
