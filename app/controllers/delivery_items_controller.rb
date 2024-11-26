# app/controllers/delivery_items_controller.rb
class DeliveryItemsController < ApplicationController
  layout "dashboard_layout"
  before_action :set_incoming_delivery
  before_action :set_project
  before_action :set_delivery_item, only: [ :show, :edit, :update, :destroy, :delete_image ]

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
    @delivery_item.user = current_user

    if @delivery_item.save
      redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                  notice: t("common.messages.created", model: DeliveryItem.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if delivery_item_params[:quantity_check_images].present?
      @delivery_item.quantity_check_images.attach(delivery_item_params[:quantity_check_images])
    end
    if delivery_item_params[:dimension_check_images].present?
      @delivery_item.dimension_check_images.attach(delivery_item_params[:dimension_check_images])
    end
    if delivery_item_params[:visual_check_images].present?
      @delivery_item.visual_check_images.attach(delivery_item_params[:visual_check_images])
    end
    if delivery_item_params[:vt2_check_images].present?
      @delivery_item.vt2_check_images.attach(delivery_item_params[:vt2_check_images])
    end
    if delivery_item_params[:ra_check_images].present?
      @delivery_item.ra_check_images.attach(delivery_item_params[:ra_check_images])
    end

    # Remove image parameters before updating other attributes
    params_without_images = delivery_item_params.except(
      :quantity_check_images,
      :dimension_check_images,
      :visual_check_images,
      :vt2_check_images,
      :ra_check_images
    )

    if @delivery_item.update(params_without_images)
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

  def delete_image
    image_type = params[:image_type]

    valid_image_types = %w[
      quantity_check_images
      dimension_check_images
      visual_check_images
      vt2_check_images
      ra_check_images
    ]

    return redirect_to_delivery_item(alert: t("common.messages.unauthorized")) unless valid_image_types.include?(image_type)

    image = @delivery_item.send(image_type).find_by(id: params[:image_id])

    if image
      image.purge
      redirect_to_delivery_item(notice: t("common.messages.file_deleted"))
    else
      redirect_to_delivery_item(alert: t("common.messages.unauthorized"))
    end
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

  def delivery_item_path_params
    {
      project_id: @project.id,
      incoming_delivery_id: @incoming_delivery.id,
      id: @delivery_item.id
    }
  end

  def redirect_to_delivery_item(notice: nil, alert: nil)
    redirect_to(
      project_incoming_delivery_delivery_item_path(delivery_item_path_params),
      notice: notice,
      alert: alert
    )
  end

  def delivery_item_params
    params.require(:delivery_item).permit(
      :name,
      :tag_number,
      :batch_number,
      :actual_quantity,
      :target_quantity,
      :quantity_check_status,
      :quantity_check_comment,
      :dimension_check_status,
      :dimension_check_comment,
      :visual_check_status,
      :visual_check_comment,
      :vt2_check_status,
      :vt2_check_comment,
      :ra_check_status,
      :ra_check_comment,
      :user_id,
      :item_description,
      {
        quantity_check_images: [],
        dimension_check_images: [],
        visual_check_images: [],
        vt2_check_images: [],
        ra_check_images: []
      },
      specifications: {}
      )
  end
end
