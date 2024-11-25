class IncomingDeliveriesController < ApplicationController
  layout "dashboard_layout"
  before_action :set_project
  before_action :set_incoming_delivery, only: [ :show, :edit, :update, :destroy ]

  def index
    @incoming_deliveries = if @project
      @project.incoming_deliveries
    else
      IncomingDelivery.all
    end
    @incoming_deliveries = @incoming_deliveries
      .includes(:project)
      .search_by_term(params[:search])
      .order(delivery_date: :desc)
  end

  def show
    if @project && @incoming_delivery
      @delivery_items = @incoming_delivery.delivery_items.includes(:quality_inspections)
    else
      flash[:alert] = "Delivery not found"
      redirect_to project_incoming_deliveries_path(@project)
    end
  end

  def new
    @incoming_delivery = @project ? @project.incoming_deliveries.build : IncomingDelivery.new
  end

  def edit
  end

  def create
    @incoming_delivery = @project.incoming_deliveries.build(incoming_delivery_params)

    if @incoming_delivery.save
      redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                  notice: "Delivery was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @incoming_delivery.update(incoming_delivery_params)
      redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                  notice: "Delivery was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @incoming_delivery.destroy
    redirect_to project_incoming_deliveries_path(@project),
                notice: "Delivery was successfully deleted."
  end

  private

  def set_project
    @project = Project.find_by(id: params[:project_id])
    unless @project
      flash[:alert] = "Project not found"
      redirect_to root_path
    end
  end

  def set_incoming_delivery
    return unless @project
    @incoming_delivery = @project.incoming_deliveries.find_by(id: params[:id])
    unless @incoming_delivery
      flash[:alert] = "Delivery not found"
      redirect_to project_incoming_deliveries_path(@project)
    end
  end

  def incoming_delivery_params
    params.require(:incoming_delivery).permit(
      :project_id,
      :delivery_date,
      :order_number,
      :supplier_name,
      :notes,
      :work_location_id,
      :delivery_note_number,
      delivery_notes: []
    )
  end
end
