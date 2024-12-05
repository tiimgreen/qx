class WeldingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_isometry
  before_action :set_welding, only: [:show, :edit, :update, :destroy]

  def index
    @weldings = @isometry.weldings
  end

  def show
  end

  def new
    @welding = @isometry.weldings.build
  end

  def edit
  end

  def create
    @welding = @isometry.weldings.build(welding_params)

    if @welding.save
      redirect_to project_isometry_path(@isometry.project, @isometry), notice: t('.success')
    else
      render :new
    end
  end

  def update
    if @welding.update(welding_params)
      redirect_to project_isometry_path(@isometry.project, @isometry), notice: t('.success')
    else
      render :edit
    end
  end

  def destroy
    @welding.destroy
    redirect_to project_isometry_path(@isometry.project, @isometry), notice: t('.success')
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
      :number, :component, :dimension, :material, :batch_number,
      :material_certificate_id, :type_code, :wps, :process, :welder,
      :rt_date, :pt_date, :vt_date, :result
    )
  end
end
