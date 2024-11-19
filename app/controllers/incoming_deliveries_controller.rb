# app/controllers/incoming_deliveries_controller.rb
class IncomingDeliveriesController < ApplicationController
  layout "dashboard_layout"
  before_action :set_incoming_delivery, only: [ :show, :edit, :update, :destroy ]
  before_action :set_project, only: [ :index, :new, :create ]

  def index
    @incoming_deliveries = if @project
      @project.incoming_deliveries
    else
      IncomingDelivery.all
    end
    @incoming_deliveries = @incoming_deliveries.includes(:project).order(delivery_date: :desc)
  end

  def show
    @delivery_items = @incoming_delivery.delivery_items.includes(:quality_inspections)
    @missing_items = @incoming_delivery.missing_delivery_items
  end

  def new
    @incoming_delivery = @project ? @project.incoming_deliveries.build : IncomingDelivery.new
  end

  def edit
  end

  def create
    @incoming_delivery = IncomingDelivery.new(incoming_delivery_params)

    if @incoming_delivery.save
      redirect_to @incoming_delivery, notice: "Delivery was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @incoming_delivery.update(incoming_delivery_params)
      redirect_to @incoming_delivery, notice: "Delivery was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @incoming_delivery.destroy
    redirect_to project_incoming_deliveries_url(@incoming_delivery.project),
                notice: "Delivery was successfully deleted."
  end

  private

  def set_incoming_delivery
    @incoming_delivery = IncomingDelivery.find(params[:id])
  end

  def set_project
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def incoming_delivery_params
    params.require(:incoming_delivery).permit(
      :project_id, :delivery_date, :order_number,
      :supplier_name, :notes,
      delivery_note: []  # For file attachment
    )
  end
end
