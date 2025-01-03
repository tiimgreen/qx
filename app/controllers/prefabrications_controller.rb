class PrefabricationsController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_prefabrication, only: [ :show, :edit, :update, :destroy, :complete ]

  def index
    @prefabrications = @project.prefabrications
                              .includes(:work_location)
                              .order(created_at: :desc)

    if params[:search].present?
      @prefabrications = @prefabrications.where("work_package_number LIKE ?", "%#{params[:search]}%")
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
    @prefabrication = @project.prefabrications.new(prefabrication_params_without_images)
    @prefabrication.user = current_user
    @prefabrication.active = true

    # Handle image attachments separately
    attach_on_hold_images if params.dig(:prefabrication, :on_hold_images).present?

    if @prefabrication.save
      redirect_to project_prefabrication_path(@project, @prefabrication),
                  notice: t("common.messages.success.created", model: Prefabrication.model_name.human)
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "prefabrication_form",
            partial: "form",
            locals: { project: @project, prefabrication: @prefabrication }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)
    attach_on_hold_images if params.dig(:prefabrication, :on_hold_images).present?

    if @prefabrication.update(prefabrication_params_without_images)
      redirect_to project_prefabrication_path(@project, @prefabrication),
                  notice: t("common.messages.success.updated", model: Prefabrication.model_name.human)
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "prefabrication_form",
            partial: "form",
            locals: { project: @project, prefabrication: @prefabrication }
          )
        }
      end
    end
  end

  def complete
    complete_resource(
      @prefabrication,
      project_prefabrication_path(@project, @prefabrication),
      {}  # No need for params, completion values will be set by complete_resource
    )
  end

  def destroy
    @prefabrication.destroy
    redirect_to project_prefabrications_path(@project),
                notice: t("common.messages.success.deleted", model: Prefabrication.model_name.human)
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_prefabrication
    @prefabrication = @project.prefabrications.find(params[:id])
  end

  def prefabrication_params
    return {} unless params[:prefabrication].present?

    params.require(:prefabrication).permit(
      :work_location_id,
      :work_package_number,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :active,
      :completed,
      :total_time,
      on_hold_images: []
    )
  end

  def prefabrication_params_without_images
    prefabrication_params.except(:on_hold_images)
  end

  def attach_on_hold_images
    return unless params.dig(:prefabrication, :on_hold_images).present?

    params[:prefabrication][:on_hold_images].each do |image|
      @prefabrication.on_hold_images.attach(image)
    end
  end

  def on_hold_params(params)
    if params[:prefabrication][:on_hold_status] == "On Hold"
      params[:prefabrication][:on_hold_date] = Time.current
      params[:prefabrication][:completed] = nil
      params[:prefabrication][:active] = true
    else
      params[:prefabrication][:on_hold_date] = nil
      params[:prefabrication][:active] = false
      params[:prefabrication][:on_hold_comment] = nil
    end
  end
end
