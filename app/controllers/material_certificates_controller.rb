class MaterialCertificatesController < ApplicationController
  layout "dashboard_layout"
  before_action :set_material_certificate, only: [ :show, :edit, :update, :destroy ]
  before_action :set_project, only: [ :new, :create ]
  before_action :ensure_project, only: [ :edit, :update ]
  before_action :load_delivery_items, only: [ :new, :edit, :create, :update ]

  def index
    @material_certificates = if params[:project_id]
      Project.find(params[:project_id]).material_certificates.includes(:delivery_items)
    else
      MaterialCertificate.includes(:project, :delivery_items).all
    end
  end

  def show
    @delivery_items = @material_certificate.delivery_items
    respond_to do |format|
      format.html
      format.pdf { render pdf: "certificate_#{@material_certificate.certificate_number}" }
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
      if params[:material_certificate][:delivery_item_ids].present?
        @material_certificate.delivery_item_ids = params[:material_certificate][:delivery_item_ids]
      end
      redirect_to @material_certificate, notice: "Material certificate was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @material_certificate.update(material_certificate_params)
      if params[:material_certificate][:delivery_item_ids].present?
        @material_certificate.delivery_item_ids = params[:material_certificate][:delivery_item_ids]
      end
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

  def load_delivery_items
    @delivery_items = if @project
      @project.delivery_items.includes(:incoming_delivery)
    else
      @material_certificate.project.delivery_items.includes(:incoming_delivery)
    end
  end

  def ensure_project
    @project = @material_certificate&.project
  end

  def material_certificate_params
    params.require(:material_certificate).permit(
      :certificate_number,
      :batch_number,
      :issue_date,
      :issuer_name,
      :description,
      :certificate_file,
      delivery_item_ids: []
    )
  end
end
