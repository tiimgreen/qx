class ProjectsController < ApplicationController
  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :edit, :update, :destroy ]

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
    params.require(:project).permit(:project_number, :name, :description, :project_manager, :client_name)
  end
end
