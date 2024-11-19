# app/controllers/roughness_measurements_controller.rb
class RoughnessMeasurementsController < ApplicationController
  layout "dashboard_layout"
  before_action :set_roughness_measurement, only: [ :show, :edit, :update, :destroy ]
  before_action :set_delivery_item, only: [ :new, :create ]

  def index
    @roughness_measurements = RoughnessMeasurement.includes(:delivery_item).all
  end

  def show
  end

  def new
    @roughness_measurement = @delivery_item.roughness_measurements.build
  end

  def edit
  end

  def create
    @roughness_measurement = @delivery_item.roughness_measurements.build(roughness_measurement_params)

    if @roughness_measurement.save
      redirect_to @roughness_measurement, notice: "Roughness measurement was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @roughness_measurement.update(roughness_measurement_params)
      redirect_to @roughness_measurement, notice: "Roughness measurement was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @roughness_measurement.destroy
    redirect_to roughness_measurements_url, notice: "Roughness measurement was successfully deleted."
  end

  private

  def set_roughness_measurement
    @roughness_measurement = RoughnessMeasurement.find(params[:id])
  end

  def set_delivery_item
    @delivery_item = DeliveryItem.find(params[:delivery_item_id])
  end

  def roughness_measurement_params
    params.require(:roughness_measurement).permit(
      :measurement_date,
      :measured_value,
      :measurement_parameters,
      :notes
    )
  end
end
