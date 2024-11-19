# app/controllers/material_certificates_controller.rb
class MaterialCertificatesController < ApplicationController
  before_action :set_material_certificate, only: [:show, :edit, :update, :destroy]
  before_action :set_project, only: [:new, :create]

  def index
    @material_certificates = if params[:project_id]
      Project.find(params[:project_id]).material_certificates
    else
      MaterialCertificate.includes(:project).all
    end
  end

  def show
    respond_to do |format|
      format.html
      format.pdf { render pdf: "certificate_#{@material_certificate.certificate_number}" } # If you want to add PDF generation
    end
  end

  def new
    @material_certificate = @project.material_certificates.build
  end

  def edit
  end

  def create
    @material_certificate = @project.material_certificates.build(material_certificate_params)

    if @material_certificate.save
      redirect_to @material_certificate, notice: "Material certificate was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @material_certificate.update(material_certificate_params)
      redirect_to @material_certificate, notice: "Material certificate was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @material_certificate.destroy
    redirect_to material_certificates_url, notice: "Material certificate was successfully deleted."
  end

  private

  def set_material_certificate
    @material_certificate = MaterialCertificate.find(params[:id])
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def material_certificate_params
    params.require(:material_certificate).permit(
      :certificate_number,
      :batch_number,
      :issue_date,
      :issuer_name,
      :description
    )
  end
end
