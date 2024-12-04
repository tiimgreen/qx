class MaterialCertificatesController < ApplicationController
  layout "dashboard_layout"
  before_action :set_material_certificate, only: [ :show, :edit, :update, :destroy ]

  def index
    @material_certificates = MaterialCertificate.all
    @material_certificates = @material_certificates.search_by_term(params[:search]) if params[:search].present?
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

  def search
    query = params[:q].to_s.strip
    @certificates = if query.present?
      MaterialCertificate
        .where("LOWER(certificate_number) LIKE :query OR LOWER(batch_number) LIKE :query",
               query: "%#{query.downcase}%")
        .limit(10)
    else
      MaterialCertificate.none
    end

    respond_to do |format|
      format.json do
        render json: @certificates.map { |cert|
          {
            id: cert.id,
            certificate_number: cert.certificate_number,
            batch_number: cert.batch_number
          }
        }
      end
    end
  rescue => e
    Rails.logger.error "Search error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: "Search failed" }, status: :internal_server_error
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
