class WeldingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_isometry
  before_action :set_welding, only: [:show, :edit, :update, :destroy]

  def index
    @weldings = @isometry.weldings.includes(:material_certificate, :material_certificate1)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @welding.to_json(include: [:material_certificate, :material_certificate1]) }
    end
  end

  def new
    @welding = @isometry.weldings.build
  end

  def edit
  end

  def create
    @welding = @isometry.weldings.build(welding_params)

    if @welding.save
      redirect_to project_isometry_path(@isometry.project, @isometry), notice: t(".success")
    else
      render :new
    end
  end

  def update
    respond_to do |format|
      if @welding.update(welding_params)
        format.html { redirect_to project_isometry_path(@isometry.project, @isometry), notice: t(".success") }
        format.json { render json: @welding.to_json(include: [:material_certificate, :material_certificate1]), status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @welding.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @welding.destroy
    redirect_to project_isometry_path(@isometry.project, @isometry), notice: t(".success")
  end

  private

  def set_isometry
    @isometry = Isometry.find(params[:isometry_id])
  end

  def set_welding
    @welding = @isometry.weldings.find(params[:id])
  end

  def welding_params
    params.require(:welding).permit(
      :number,
      :component, :component1,
      :dimension, :dimension1,
      :material, :material1,
      :batch_number, :batch_number1,
      :material_certificate_id, :material_certificate1_id,
      :type_code, :type_code1,
      :wps, :wps1,
      :process, :process1,
      :welder, :welder1,
      :rt_date, :rt_date1,
      :pt_date, :pt_date1,
      :vt_date, :vt_date1,
      :result, :result1,
      :rt_done_by, :rt_done_by1,
      :pt_done_by, :pt_done_by1,
      :vt_done_by, :vt_done_by1
    )
  end
end
