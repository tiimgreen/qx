# app/controllers/inspection_defects_controller.rb
class InspectionDefectsController < ApplicationController
  before_action :set_inspection_defect, only: [ :show, :edit, :update, :destroy ]
  before_action :set_quality_inspection, only: [ :new, :create ]

  def index
    @inspection_defects = InspectionDefect.includes(:quality_inspection)
    @inspection_defects = @inspection_defects.where(quality_inspection_id: params[:quality_inspection_id]) if params[:quality_inspection_id]
  end

  def show
  end

  def new
    @inspection_defect = @quality_inspection.inspection_defects.build
  end

  def edit
  end

  def create
    @inspection_defect = @quality_inspection.inspection_defects.build(inspection_defect_params)

    if @inspection_defect.save
      redirect_to @inspection_defect, notice: "Defect was successfully recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @inspection_defect.update(inspection_defect_params)
      redirect_to @inspection_defect, notice: "Defect was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @inspection_defect.destroy
    redirect_to quality_inspection_inspection_defects_url(@inspection_defect.quality_inspection),
                notice: "Defect was successfully deleted."
  end

  private

  def set_inspection_defect
    @inspection_defect = InspectionDefect.find(params[:id])
  end

  def set_quality_inspection
    @quality_inspection = QualityInspection.find(params[:quality_inspection_id])
  end

  def inspection_defect_params
    params.require(:inspection_defect).permit(
      :description,
      :severity,
      :corrective_action
    )
  end
end
