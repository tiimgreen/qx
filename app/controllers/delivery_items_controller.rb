class DeliveryItemsController < ApplicationController
  include CompletableController

  layout "dashboard_layout"
  before_action :set_incoming_delivery
  before_action :set_project
  before_action :set_delivery_item, only: [ :show, :edit, :update, :destroy, :delete_image ]

  def index
    @delivery_items = @incoming_delivery.delivery_items
                                      .search_by_term(params[:search])
  end

  def show
  end

  def new
    @delivery_item = @incoming_delivery.delivery_items.build
  end

  def edit
  end

  def create
    @delivery_item = @incoming_delivery.delivery_items.build
    @delivery_item.assign_attributes(delivery_item_params.to_h)
    @delivery_item.user = current_user

    # Set on_hold_date when status is On Hold
    @delivery_item.on_hold_date = Time.current if @delivery_item.on_hold_status == "On Hold"

    if @delivery_item.save
      redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                  notice: t("common.messages.created", model: DeliveryItem.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if params[:complete_delivery_item]
      complete
    else
      # Handle image attachments first
      attach_images if images_present_in_params?

      # Process remaining attributes
      params_without_images = remove_image_params(delivery_item_params)

      # Set on_hold_date when status is On Hold
      if params_without_images[:on_hold_status] == "On Hold"
        params_without_images[:on_hold_date] = Time.current
      end

      if @delivery_item.update(params_without_images)
        @incoming_delivery.update_completion_status
        redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                  notice: t("common.messages.updated", model: DeliveryItem.model_name.human)
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @delivery_item.destroy
    redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                notice: t("common.messages.deleted", model: DeliveryItem.model_name.human)
  end

  def complete
    complete_resource(
      @delivery_item,
      project_incoming_delivery_delivery_item_path(@project, @incoming_delivery, @delivery_item),
      delivery_item_params
    )
  end

  def delete_image
    image_type = params[:image_type]
    return handle_invalid_image_type unless valid_image_type?(image_type)

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
    @project = @incoming_delivery&.project
    unless @project
      redirect_to root_path, alert: t("common.messages.project_not_found")
    end
  end

  def set_delivery_item
    @delivery_item = if params[:id]
      DeliveryItem.find(params[:id])
    else
      @incoming_delivery.delivery_items.build
    end
  end

  def attach_images
    IMAGE_TYPES.each do |image_type|
      if delivery_item_params[image_type].present?
        @delivery_item.send(image_type).attach(delivery_item_params[image_type])
      end
    end
  end

  def images_present_in_params?
    IMAGE_TYPES.any? { |type| delivery_item_params[type].present? }
  end

  def remove_image_params(params)
    params.except(*IMAGE_TYPES)
  end

  def valid_image_type?(image_type)
    IMAGE_TYPES.include?(image_type)
  end

  def handle_invalid_image_type
    redirect_to_delivery_item(alert: t("common.messages.unauthorized"))
  end

  IMAGE_TYPES = %w[
    quantity_check_images
    dimension_check_images
    visual_check_images
    vt2_check_images
    ra_check_images
    on_hold_images
  ].freeze

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
      :delivery_note_position,
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
      :ra_date,
      :ra_value,
      :ra_parameters,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :total_time,
      :user_id,
      *completable_params,
      :item_description,
      {
        quantity_check_images: [],
        dimension_check_images: [],
        visual_check_images: [],
        vt2_check_images: [],
        ra_check_images: []
      },
      specifications: {},
      on_hold_images: []
    )
  end
end
