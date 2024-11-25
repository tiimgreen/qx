# app/controllers/delivery_items_controller.rb
class DeliveryItemsController < ApplicationController
  layout "dashboard_layout"
  before_action :set_incoming_delivery
  before_action :set_project
  before_action :set_delivery_item, only: [ :show, :edit, :update, :destroy ]

  def index
    @delivery_items = @incoming_delivery.delivery_items
                                      .includes(:quality_inspections)
                                      .search_by_term(params[:search])
  end

  def show
    @delivery_item = DeliveryItem.includes(:quality_inspections,
                                          :roughness_measurement,
                                          :material_certificates)
                              .find(params[:id])
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
      redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                  notice: t("common.messages.created", model: DeliveryItem.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @delivery_item.update(delivery_item_params)
      redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                  notice: t("common.messages.updated", model: DeliveryItem.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @delivery_item.destroy
    redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                notice: t("common.messages.deleted", model: DeliveryItem.model_name.human)
  end

  private

  def set_incoming_delivery
    @incoming_delivery = if params[:incoming_delivery_id]
      IncomingDelivery.find(params[:incoming_delivery_id])
    elsif params[:id]
      DeliveryItem.find(params[:id]).incoming_delivery
    end
  end

  def set_project
    @project = @incoming_delivery.project if @incoming_delivery
  end

  def set_delivery_item
    @delivery_item = if params[:id]
      DeliveryItem.find(params[:id])
    else
      @incoming_delivery.delivery_items.build
    end
  end

  def delivery_item_params
    params.require(:delivery_item).permit(
      :tag_number,
      :batch_number,
      :quantity_received,
      :item_description,
      specifications: {}
    )
  end
end
