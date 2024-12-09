class IsometriesController < ApplicationController
  include CompletableController

  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, only: [ :show, :edit, :update, :destroy, :remove_certificate, :delete_image, :download_welding_report ]
  before_action :authorize_action!

  def index
    base_scope = if @project
      @project.isometries.active
    else
      Isometry.active
    end

    sort_column = sort_params || "received_date"
    sort_direction = params[:direction] || "desc"

    @isometries = base_scope
      .includes(:project, :sector, :weldings)
      .search_by_term(params[:search])
      .order(sort_column => sort_direction)
  end

  def show
  end

  def new
    @isometry = @project.isometries.build
  end

  def edit
  end

  def create
    @isometry = @project.isometries.build(isometry_params)
    @isometry.user = current_user

    # Handle new PDF upload
    handle_new_pdf_upload(@isometry)

    if @isometry.save
      redirect_to project_isometry_path(@project, @isometry),
                  notice: t("common.messages.created", model: "Isometry")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # Handle new PDF upload first
    handle_new_pdf_upload(@isometry)

    # Handle image attachments
    if params[:isometry][:rt_images].present?
      @isometry.rt_images.attach(params[:isometry][:rt_images])
    end
    if params[:isometry][:vt_images].present?
      @isometry.vt_images.attach(params[:isometry][:vt_images])
    end
    if params[:isometry][:pt_images].present?
      @isometry.pt_images.attach(params[:isometry][:pt_images])
    end

    # Remove image parameters before updating other attributes to prevent overwriting
    update_params = isometry_params.except(:rt_images, :vt_images, :pt_images)

    # Then update other attributes
    if @isometry.update(update_params)
      redirect_to project_isometry_path(@project, @isometry),
                  notice: t("common.messages.updated", model: "Isometry")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @isometry.update(deleted: true)
    redirect_to project_isometries_path(@project),
                notice: t("common.messages.deleted", model: "Isometry")
  end

  def remove_certificate
    @isometry = Isometry.find(params[:id])
    certificate = MaterialCertificate.find(params[:certificate_id])

    if @isometry.material_certificates.include?(certificate)
      @isometry.material_certificates.delete(certificate)
      head :ok
    else
      head :not_found
    end
  end

  def delete_image
    begin
      image_type = params[:image_type]
      image_id = params[:image_id]

      Rails.logger.info "Attempting to delete image: #{image_type} #{image_id}"

      # Get the attachments collection based on image type
      attachments = case image_type
      when "rt"
        @isometry.rt_images
      when "vt"
        @isometry.vt_images
      when "pt"
        @isometry.pt_images
      end

      # Find the specific attachment by blob ID
      if attachments
        # Look through the attachments to find the one with matching blob
        attachment = attachments.attachments.find { |a| a.blob.signed_id == image_id }

        if attachment
          Rails.logger.info "Found attachment, attempting to purge"
          attachment.purge
          head :ok
        else
          Rails.logger.error "Attachment not found for signed_id: #{image_id}"
          head :not_found
        end
      else
        Rails.logger.error "Invalid image type: #{image_type}"
        head :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Error deleting image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      head :internal_server_error
    end
  end

  def download_welding_report
    pdf = ::WeldingPdfGenerator.new(@isometry).generate
    
    send_data pdf.render,
              filename: "welding_report_#{@isometry.line_id}.pdf",
              type: 'application/pdf',
              disposition: params[:download] ? 'attachment' : 'inline'
  end

  private

  def authorize_action!
    case action_name
    when "index", "show"
      authorize_view!
    when "new", "create"
      authorize_create!
    when "edit", "update", "delete_image", "download_welding_report"
      authorize_edit!
    when "destroy"
      authorize_destroy!
    when "remove_certificate"
      authorize_edit!
    end
  end

  def authorize_view!
    unless current_user.can_view?("Isometry")
      flash[:alert] = "You don't have permission to view isometries"
      redirect_to request.referer || projects_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("Isometry")
      flash[:alert] = "You don't have permission to create isometries"
      redirect_to request.referer || projects_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("Isometry")
      flash[:alert] = "You don't have permission to update isometries"
      redirect_to request.referer || projects_path
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("Isometry")
      flash[:alert] = "You don't have permission to delete isometries"
      redirect_to request.referer || projects_path
    end
  end

  def sort_params
    allowed_columns = %w[
      received_date
      line_id
      pid_number
      system
      revision_number
      on_hold_status
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    @project = Project.find_by(id: params[:project_id])
    unless @project
      flash[:alert] = "Project not found"
      redirect_to root_path
    end
  end

  def set_isometry
    return unless @project
    @isometry = @project.isometries.find_by(id: params[:id])
    unless @isometry
      flash[:alert] = "Isometry not found"
      redirect_to project_isometries_path(@project)
    end
  end

  def handle_new_pdf_upload(isometry)
    if params.dig(:isometry, :new_pdf).present?
      isometry.isometry_documents.build(
        pdf: params[:isometry][:new_pdf],
        qr_position: params[:isometry][:new_pdf_qr_position]
      )
    end
  end

  def isometry_params
    params.require(:isometry).permit(
      :line_id,
      :line_id_2,
      :line_id_3,
      :line_id_4,
      :line_id_5,
      :line_id_6,
      :line_id_7,
      :line_id_8,
      :line_id_9,
      :line_id_10,
      :pipe_length,
      :workshop_sn,
      :assembly_sn,
      :total_sn,
      :revision_number,
      :revision_last,
      :page_number,
      :page_total,
      :sector_id,
      :notes,
      :qr_position,
      :on_hold_status,
      :on_hold_comment,
      :received_date,
      :pid_number,
      :pid_revision,
      :ped_category,
      :gmp,
      :gdp,
      :pipe_class,
      :material,
      :system,
      :dn,
      :medium,
      :total_supports,
      :total_spools,
      :rt,
      :vt2,
      :pt2,
      :dp,
      :dip,
      :isolation_required,
      :slope_if_needed,
      :work_package_number,
      material_certificate_ids: [],
      isometry_documents_attributes: [ :id, :qr_position, :_destroy ],
      weldings_attributes: [
        :id, :number, :component, :dimension, :material, :batch_number,
        :material_certificate_id, :type_code, :wps, :process, :welder,
        :rt_date, :pt_date, :vt_date, :result, :_destroy
      ],
      rt_images: [],
      vt_images: [],
      pt_images: [],
    )
  end

  def isometry_images_present_in_params?
    params.dig(:isometry, :isometry_images)&.any?
  end

  def attach_isometry_images
    params[:isometry][:isometry_images].each do |image|
      @isometry.isometry_images.attach(image)
    end
  end

  def remove_isometry_images_params(params_hash)
    params_hash.except(:isometry_images)
  end
end
