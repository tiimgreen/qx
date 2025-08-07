class IsometriesController < ApplicationController
  include CompletableController

  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, only: [ :show, :edit, :update, :destroy, :remove_certificate, :download_welding_report, :new_page, :create_revision ]
  before_action :authorize_action!

  def index
    base_scope = if @project
      @project.isometries
    else
      Isometry.active
    end

    @isometries = base_scope.includes(:project, :sector, :weldings)

    # Apply revision filter
    case params[:revision_filter]
    when "all"
      # Show all revisions
    when "old"
      @isometries = @isometries.where(revision_last: false)
    else # 'latest' or nil
      @isometries = @isometries.where(revision_last: true)
    end

    if params[:search].present?
      @isometries = @isometries.search_by_term(params[:search])
    end

    sort_column = sort_params || "line_id"  # Change default sort to line_id
    sort_direction = params[:direction] || "asc"

    # If using default sort (line_id), add secondary sorts for page_number and id
    if sort_column == "line_id"
      @isometries = @isometries.reorder(line_id: sort_direction)
                              .order(page_number: sort_direction, id: :asc)
    elsif sort_column == "received_date"
      @isometries = @isometries.reorder(Arel.sql("received_date #{sort_direction} NULLS LAST"))
    else
      @isometries = @isometries.reorder(sort_column => sort_direction)
    end

    @pagy, @isometries = pagy(@isometries)
  end

  def show
  end

  def new
    @isometry = @project.isometries.build
  end

  def edit
  end

  def create
    # Remove file upload parameters before creating the isometry
    create_params = isometry_params.except(
      :rt_images, :vt_images, :pt_images, :new_pdf, :new_pdf_qr_position, :on_hold_images
    )

    @isometry = @project.isometries.new(create_params)
    @isometry.user = current_user
    @isometry.received_date = Time.now

    respond_to do |format|
      format.html do
        if @isometry.save
          # Handle new PDF upload and images using Docuvita after saving
          handle_docuvita_pdf_upload(@isometry)
          handle_docuvita_image_uploads(@isometry)

          redirect_to project_isometry_path(@project, @isometry),
                      notice: t("common.messages.success.created", model: "Isometry")
        else
          render :new, status: :unprocessable_entity
        end
      end

      format.json do
        @isometry.draft = true
        if @isometry.save(validate: false)
          render json: {
            status: "success",
            message: "Draft saved",
            id: @isometry.id
          }
        else
          render json: {
            status: "error",
            message: @isometry.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    respond_to do |format|
      format.html do
        update_params = isometry_params.except(
          :rt_images, :vt_images, :pt_images, :new_pdf, :new_pdf_qr_position, :on_hold_images
        )

        if @isometry.update(update_params)
          begin
            handle_docuvita_pdf_upload(@isometry) if params.dig(:isometry, :new_pdf).present?
            handle_docuvita_image_uploads(@isometry)
            redirect_to project_isometry_path(@project, @isometry),
                      notice: t("common.messages.success.updated", model: "Isometry")
          rescue => e
            flash.now[:alert] = e.message
            render :edit, status: :unprocessable_entity
          end
        else
          render :edit, status: :unprocessable_entity
        end
      end

      format.json do
        # For autosave, only exclude image parameters
        save_params = isometry_params.except(
          :rt_images, :vt_images, :pt_images, :new_pdf, :new_pdf_qr_position, :on_hold_images
        )
        @isometry.assign_attributes(save_params)
        @isometry.draft = true
        if @isometry.save(validate: false)
          render json: {
            status: "success",
            message: "Draft saved",
            id: @isometry.id
          }
        else
          render json: {
            status: "error",
            message: @isometry.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    if destroy_isometry_associations(@isometry)
      redirect_to project_isometries_path(@project, locale: I18n.locale),
                  notice: t("common.messages.success.deleted", model: "Isometry")
    else
      redirect_to project_isometries_path(@project, locale: I18n.locale),
                  alert: "Failed to delete isometry: #{@isometry.errors.full_messages.join(', ')}"
    end
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

  def download_welding_report
    pdf = ::WeldingPdfGenerator.new(@isometry).generate

    send_data pdf.render,
              filename: "welding_report_#{@isometry.line_id}.pdf",
              type: "application/pdf",
              disposition: params[:download] ? "attachment" : "inline"
  end

  def new_page
    @isometry = @project.isometries.find(params[:id])
    service = IsometryPageCreator.new(@isometry)
    new_isometry = service.create_new_page

    redirect_to project_isometry_path(@project, new_isometry), notice: t("isometries.notices.page_created")
  rescue => e
    redirect_to project_isometry_path(@project, @isometry), alert: t("isometries.errors.page_creation_failed")
  end

  def create_revision
    @isometry = @project.isometries.find(params[:id])
    service = IsometryRevisionCreator.new(@isometry)
    new_isometry = service.create_revision

    if new_isometry
      redirect_to project_isometry_path(@project, new_isometry), notice: t(".revision_created")
    else
      redirect_to project_isometries_path(@project), alert: t(".revision_failed")
    end
  end

  def autosave
    @isometry = @project.isometries.new(isometry_params)
    @isometry.draft = true

    if @isometry.save(validate: false)
      render json: { status: "success", message: "Draft saved" }
    else
      render json: { status: "error", message: @isometry.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def search_work_packages
    isometries = @project.isometries
                        .where("work_package_number LIKE ?", "%#{params[:query]}%")
                        .select(:id, :work_package_number, :line_id)
                        .limit(10).distinct

    render json: isometries.map { |i| {
      id: i.id,
      label: "#{i.work_package_number} - #{i.line_id}",
      value: i.work_package_number
    }}
  rescue => e
    Rails.logger.error "Error in search_work_packages: #{e.message}"
    render json: [], status: :ok
  end

  def search_batch_numbers
    Rails.logger.debug "Search params: #{params.inspect}"
    query = params[:query]

    delivery_items = DeliveryItem
                     .where("batch_number LIKE ?", "%#{query}%")
                     .select(:id, :batch_number)
                     .limit(10)

    render json: delivery_items.map { |i| {
      id: i.id,
      label: i.batch_number,
      value: i.batch_number
    }}
  rescue => e
    Rails.logger.error "Error in search_batch_numbers: #{e.message}"
    render json: [], status: :ok
  end

  private

  def authorize_action!
    case action_name
    when "index", "show"
      authorize_view!
    when "new", "create"
      authorize_create!
    when "edit", "update", "download_welding_report", "new_page", "create_revision"
      authorize_edit!
    when "destroy"
      authorize_destroy!
    when "remove_certificate"
      authorize_edit!
    when "autosave"
      authorize_create!
    when "search_work_packages"
      authorize_view!
    end
  end

  def authorize_view!
    unless current_user.can_view?("Isometry")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: Isometry.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("Isometry")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: Isometry.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("Isometry")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: Isometry.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("Isometry")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: Isometry.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def sort_params
    allowed_columns = %w[
      line_id work_package_number system pid_number
      material medium pipe_class revision_number
      page_number page_total received_date
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

  def handle_docuvita_pdf_upload(isometry)
    if params.dig(:isometry, :new_pdf).present? && params[:isometry][:new_pdf].is_a?(ActionDispatch::Http::UploadedFile)
      pdf_file = params[:isometry][:new_pdf]
      qr_position = params.dig(:isometry, :new_pdf_qr_position).presence

      isometry.upload_pdf_to_docuvita(
        pdf_file,
        pdf_file.original_filename, "isometry", "isometry",
        { qr_position: qr_position }
      )
    end
  end

  def handle_docuvita_image_uploads(isometry)
    if params.dig(:isometry, :rt_images).present?
      params[:isometry][:rt_images].each do |file|
        next unless file.is_a?(ActionDispatch::Http::UploadedFile)
        if file.content_type == "application/pdf"
          isometry.upload_pdf_to_docuvita(file, file.original_filename, "rt_image", "isometry")
        else
          isometry.upload_image_to_docuvita(file, file.original_filename, "rt_image", "isometry")
        end
      end
    end

    if params.dig(:isometry, :vt_images).present?
      params[:isometry][:vt_images].each do |file|
        next unless file.is_a?(ActionDispatch::Http::UploadedFile)
        if file.content_type == "application/pdf"
          isometry.upload_pdf_to_docuvita(file, file.original_filename, "vt_image", "isometry")
        else
          isometry.upload_image_to_docuvita(file, file.original_filename, "vt_image", "isometry")
        end
      end
    end

    if params.dig(:isometry, :pt_images).present?
      params[:isometry][:pt_images].each do |file|
        next unless file.is_a?(ActionDispatch::Http::UploadedFile)
        if file.content_type == "application/pdf"
          isometry.upload_pdf_to_docuvita(file, file.original_filename, "pt_image", "isometry")
        else
          isometry.upload_image_to_docuvita(file, file.original_filename, "pt_image", "isometry")
        end
      end
    end

    if params.dig(:isometry, :on_hold_images).present?
      params[:isometry][:on_hold_images].each do |file|
        next unless file.is_a?(ActionDispatch::Http::UploadedFile)
        if file.content_type == "application/pdf"
          isometry.upload_pdf_to_docuvita(file, file.original_filename, "on_hold_image", "isometry")
        else
          isometry.upload_image_to_docuvita(file, file.original_filename, "on_hold_image", "isometry")
        end
      end
    end
  end

  def isometry_params
    params.require(:isometry).permit(
      :received_date, :pid_number, :pid_revision, :line_id, :dn,
      :revision_number, :revision_letter, :page_number, :page_total, :pipe_class,
      :material, :system, :medium, :work_package_number, :revision_last,
      :dp, :dip, :isolation_required, :approved_for_production, :gmp, :gdp, :ped_category,
      :slope_if_needed, :rt, :vt2, :pt2, :pipe_length, :workshop_sn,
      :assembly_sn, :total_sn, :total_supports, :total_spools,
      :on_hold_status, :on_hold_comment, :notes, :qr_position, :draft,
      :new_pdf, :new_pdf_qr_position, :additional_empty_rows,
      rt_images: [], vt_images: [], pt_images: [], on_hold_images: [],
      material_certificate_ids: [],
      isometry_documents_attributes: [ :id, :qr_position, :_destroy ],
      weldings_attributes: [
        :id, :number, :component, :component1, :dimension, :dimension1,
        :material, :material1, :batch_number, :batch_number1,
        :material_certificate_id, :material_certificate1_id,
        :type_code, :type_code1, :wps, :wps1, :process, :process1,
        :welder, :welder1, :rt_date1, :pt_date1, :vt_date1,
        :result, :result1, :rt_done_by, :pt_done_by, :vt_done_by,
        :is_orbital, :is_manuell, :_destroy
      ]
    )
  end

  def destroy_isometry_associations(isometry)
    ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF;")

    begin
      ActiveRecord::Base.transaction do
        # First, handle any Active Storage attachments
        isometry.qr_code.purge_later if isometry.qr_code.attached?

        # Handle has_many associations
        isometry.isometry_material_certificates.delete_all
        isometry.weldings.delete_all
        isometry.work_preparations.destroy_all
        isometry.test_packs.destroy_all
        isometry.docuvita_documents.destroy_all

        # Handle has_one associations
        isometry.prefabrication&.destroy
        isometry.final_inspection&.destroy
        isometry.transport&.destroy
        isometry.site_delivery&.destroy
        isometry.site_assembly&.destroy
        isometry.on_site&.destroy
        isometry.pre_welding&.destroy

        # Handle incoming_delivery and its items
        if isometry.incoming_delivery
          isometry.incoming_delivery.delivery_items.delete_all
          isometry.incoming_delivery.destroy
        end

        # Finally, delete the isometry
        isometry.destroy
      end
      true
    rescue => e
      Rails.logger.error "Failed to delete isometry #{isometry.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      false
    ensure
      # Always re-enable foreign keys after we're done
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON;")
    end
  end
end
