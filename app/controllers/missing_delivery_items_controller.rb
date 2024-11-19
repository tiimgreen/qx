# app/controllers/missing_delivery_items_controller.rb
class MissingDeliveryItemsController < ApplicationController
  layout "dashboard_layout"
  before_action :set_missing_delivery_item, only: [ :show, :edit, :update, :destroy ]
  before_action :set_incoming_delivery, only: [ :new, :create ]

  def index
    @missing_delivery_items = MissingDeliveryItem.includes(:incoming_delivery)
    @missing_delivery_items = @missing_delivery_items.where(incoming_delivery_id: params[:incoming_delivery_id]) if params[:incoming_delivery_id]
  end

  def show
  end

  def new
    @missing_delivery_item = @incoming_delivery.missing_delivery_items.build
  end

  def edit
  end

  def create
    @missing_delivery_item = @incoming_delivery.missing_delivery_items.build(missing_delivery_item_params)

    if @missing_delivery_item.save
      redirect_to @missing_delivery_item, notice: "Missing delivery item was successfully recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @missing_delivery_item.update(missing_delivery_item_params)
      redirect_to @missing_delivery_item, notice: "Missing delivery item was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @missing_delivery_item.destroy
    redirect_to incoming_delivery_missing_delivery_items_url(@missing_delivery_item.incoming_delivery),
                notice: "Missing delivery item was successfully deleted."
  end

  private

  def set_missing_delivery_item
    @missing_delivery_item = MissingDeliveryItem.find(params[:id])
  end

  def set_incoming_delivery
    @incoming_delivery = IncomingDelivery.find(params[:incoming_delivery_id])
  end

  def missing_delivery_item_params
    params.require(:missing_delivery_item).permit(
      :expected_quantity,
      :description,
      :order_line_reference
    )
  end
end
