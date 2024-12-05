class MaterialCertificatesController < ApplicationController
  layout "dashboard_layout"
  before_action :authenticate_user!

  before_action :set_material_certificate, only: [ :show, :edit, :update, :destroy ]

  def index
    @material_certificates = MaterialCertificate.all
  end

  def search
    query = (params[:q] || params[:query])&.strip&.downcase
    @certificates = if query.present?
      MaterialCertificate.where("LOWER(batch_number) LIKE ? OR LOWER(certificate_number) LIKE ?", 
                               "%#{query}%", "%#{query}%")
                        .limit(10)
    else
      MaterialCertificate.none
    end

    respond_to do |format|
      format.json { render json: @certificates.as_json(only: [:id, :batch_number, :certificate_number]) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.pdf { render pdf: "certificate_#{@material_certificate.certificate_number}" }
    end
  end

  def new
    @material_certificate = MaterialCertificate.new
  end

  def edit
  end

  def create
    @material_certificate = MaterialCertificate.new(material_certificate_params)

    if @material_certificate.save
      redirect_to @material_certificate, notice: t(".success")
    else
      render :new
    end
  end

  def update
    if @material_certificate.update(material_certificate_params)
      redirect_to @material_certificate, notice: t(".success")
    else
      render :edit
    end
  end

  def destroy
    @material_certificate.destroy
    redirect_to material_certificates_url, notice: t(".success")
  end

  private

  def set_material_certificate
    @material_certificate = MaterialCertificate.find(params[:id])
  end

  def material_certificate_params
    params.require(:material_certificate).permit(
      :certificate_number,
      :batch_number,
      :issue_date,
      :issuer_name,
      :description,
      :line_id,
      :certificate_file
    )
  end
end
