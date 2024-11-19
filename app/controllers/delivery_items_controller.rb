# app/controllers/delivery_items_controller.rb
class DeliveryItemsController < ApplicationController
  before_action :set_delivery_item, only: [ :show, :edit, :update, :destroy ]
  before_action :set_incoming_delivery, only: [ :index, :new, :create ]

  def index
    @delivery_items = if @incoming_delivery
      @incoming_delivery.delivery_items
    else
      DeliveryItem.all
    end
    @delivery_items = @delivery_items.includes(:incoming_delivery)
  end

  def show
    @quality_inspections = @delivery_item.quality_inspections.includes(:inspection_defects)
    @roughness_measurement = @delivery_item.roughness_measurement
  end

  def new
    @delivery_item = @incoming_delivery.delivery_items.build
  end

  def edit
  end

  def create
    @delivery_item = @incoming_delivery.delivery_items.build(delivery_item_params)

    if @delivery_item.save
      redirect_to @incoming_delivery, notice: "Item was successfully added to delivery."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @delivery_item.update(delivery_item_params)
      redirect_to @delivery_item.incoming_delivery, notice: "Item was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    incoming_delivery = @delivery_item.incoming_delivery
    @delivery_item.destroy
    redirect_to incoming_delivery, notice: "Item was successfully removed."
  end

  private

  def set_delivery_item
    @delivery_item = DeliveryItem.find(params[:id])
  end

  def set_incoming_delivery
    @incoming_delivery = IncomingDelivery.find(params[:incoming_delivery_id]) if params[:incoming_delivery_id]
  end

  def delivery_item_params
    params.require(:delivery_item).permit(
      :tag_number, :batch_number, :quantity_received,
      :item_description, specifications: {}
    )
  end
end
