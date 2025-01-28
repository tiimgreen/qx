class MaterialCertificatesController < ApplicationController
  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_material_certificate, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_action!

  def index
    sort_column = sort_params || "created_at"
    sort_direction = params[:direction] || "asc"

    @pagy, @material_certificates = pagy(
      MaterialCertificate.search_by_term(params[:search])
                        .order(sort_column => sort_direction)
    )
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
      format.json { render json: @certificates.as_json(only: [ :id, :batch_number, :certificate_number ]) }
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

    respond_to do |format|
      format.html { redirect_to material_certificates_url, notice: t(".success") }
      format.json { head :no_content }
    end
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

  def sort_params
    allowed_columns = %w[
      certificate_number
      batch_number
      line_id
      issue_date
      issuer_name
      created_at
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def authorize_action!
    case action_name
    when "index", "show"
      authorize_view!
    when "new", "create"
      authorize_create!
    when "edit", "update"
      authorize_edit!
    when "destroy"
      authorize_destroy!
    end
  end

  def authorize_view!
    unless current_user.can_view?("MaterialCertificate")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: MaterialCertificate.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("MaterialCertificate")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: MaterialCertificate.model_name.human)
      redirect_to request.referer || material_certificates_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("MaterialCertificate")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: MaterialCertificate.model_name.human)
      redirect_to request.referer || material_certificate_path(@material_certificate)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("MaterialCertificate")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: MaterialCertificate.model_name.human)
      redirect_to request.referer || material_certificate_path(@material_certificate)
    end
  end
end
