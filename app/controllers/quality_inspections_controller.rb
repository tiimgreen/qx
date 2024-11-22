# app/controllers/quality_inspections_controller.rb
class QualityInspectionsController < ApplicationController
  layout "dashboard_layout"
  before_action :set_quality_inspection, only: [ :show, :edit, :update, :destroy ]
  before_action :set_delivery_item, only: [ :index, :new, :create ]

  def index
    @quality_inspections = if @delivery_item
      @delivery_item.quality_inspections
    else
      QualityInspection.all
    end
    @quality_inspections = @quality_inspections
      .includes(:delivery_item, :inspection_defects)
      .search_by_term(params[:search])
  end

  def show
  end

  def new
    @quality_inspection = @delivery_item.quality_inspections.build
  end

  def edit
  end

  def create
    @quality_inspection = @delivery_item.quality_inspections.build(quality_inspection_params)
    @quality_inspection.inspector ||= current_user

    if @quality_inspection.save
      redirect_to @delivery_item, notice: "Inspection was successfully recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @quality_inspection.update(quality_inspection_params)
      redirect_to @quality_inspection.delivery_item, notice: "Inspection was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    delivery_item = @quality_inspection.delivery_item
    @quality_inspection.destroy
    redirect_to delivery_item, notice: "Inspection was successfully deleted."
  end

  def remove_image
    @quality_inspection = QualityInspection.find(params[:id])
    image = @quality_inspection.images.find(params[:image_id])
    image.purge

    respond_to do |format|
      format.html { redirect_to edit_quality_inspection_path(@quality_inspection), notice: t(".image_removed") }
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(image)) }
    end
  end

  private

  def set_quality_inspection
    @quality_inspection = QualityInspection.find(params[:id])
  end

  def set_delivery_item
    @delivery_item = DeliveryItem.find(params[:delivery_item_id]) if params[:delivery_item_id]
  end

  def quality_inspection_params
    params.require(:quality_inspection).permit(
      :inspection_type,
      :inspector_id,
      :inspection_date,
      :status,
      :notes,
      images: [],
      inspection_defects_attributes: [ :id, :description, :severity, :corrective_action, :_destroy ]
    )
  end
end
