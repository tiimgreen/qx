class PrefabricationsController < ApplicationController
  before_action :set_project
  before_action :set_prefabrication, only: [ :show, :edit, :update, :destroy, :complete ]

  def index
    @prefabrications = @project.prefabrications
                              .includes(:work_location)
                              .order(created_at: :desc)

    if params[:search].present?
      @prefabrications = @prefabrications.where("work_package_number ILIKE ?", "%#{params[:search]}%")
    end

    if params[:sort].present?
      direction = params[:direction] == "desc" ? "desc" : "asc"
      @prefabrications = @prefabrications.order("#{params[:sort]} #{direction}")
    end

    respond_to do |format|
      format.html
      format.json { render json: @prefabrications }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @prefabrication }
    end
  end

  def new
    @prefabrication = @project.prefabrications.new
  end

  def edit
  end

  def create
    @prefabrication = @project.prefabrications.new(prefabrication_params)
    @prefabrication.user = current_user
    @prefabrication.active = true

    if @prefabrication.save
      redirect_to project_prefabrication_path(@project, @prefabrication),
                  notice: t("common.messages.success.created", model: Prefabrication.model_name.human)
    else
      render :new
    end
  end

  def update
    if @prefabrication.update(prefabrication_params)
      redirect_to project_prefabrication_path(@project, @prefabrication),
                  notice: t("common.messages.success.updated", model: Prefabrication.model_name.human)
    else
      render :edit
    end
  end

  def complete
    debugger
    Rails.logger.info "Complete action called for prefabrication #{@prefabrication.id}"
    Rails.logger.info "Current params: #{params.inspect}"

    if @prefabrication.update(completed: Time.current, active: false)
      Rails.logger.info "Successfully completed prefabrication"
      redirect_to project_prefabrication_path(@project, @prefabrication),
                  notice: t("common.messages.success.completed", model: Prefabrication.model_name.human)
    else
      Rails.logger.error "Failed to complete prefabrication: #{@prefabrication.errors.full_messages}"
      redirect_to project_prefabrication_path(@project, @prefabrication),
                  alert: t("common.messages.failure.complete", model: Prefabrication.model_name.human)
    end
  end

  def destroy
    @prefabrication.destroy
    redirect_to project_prefabrications_path(@project),
                notice: t("common.messages.success.deleted", model: Prefabrication.model_name.human)
  end

  def search_isometries
    isometries = @project.isometries.where("work_package_number ILIKE ?", "%#{params[:term]}%")
    render json: isometries.map { |i| { label: i.work_package_number, value: i.work_package_number } }
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_prefabrication
    @prefabrication = @project.prefabrications.find(params[:id])
  end

  def prefabrication_params
    params.require(:prefabrication).permit(
      :work_location_id,
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      on_hold_images: []
    )
  end
end
