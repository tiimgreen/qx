class IsometriesController < ApplicationController
  include CompletableController

  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, only: [ :show, :edit, :update, :destroy, :remove_certificate, :download_welding_report, :new_page, :create_revision ]
  before_action :authorize_action!

  def index
    base_scope = if @project
      @project.isometries.active
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
    @isometry = @project.isometries.new(isometry_params)
    @isometry.user = current_user
    @isometry.received_date = Time.now

    respond_to do |format|
      format.html do
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

        # Remove image parameters before saving
        create_params = isometry_params.except(:rt_images, :vt_images, :pt_images)
        @isometry.assign_attributes(create_params)

        if @isometry.save
          redirect_to project_isometry_path(@project, @isometry),
                      notice: t("common.messages.created", model: "Isometry")
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

        # Remove only image parameters before updating
        update_params = isometry_params.except(:rt_images, :vt_images, :pt_images)

        if @isometry.update(update_params)  # This will handle weldings through nested attributes
          redirect_to project_isometry_path(@project, @isometry),
                      notice: t("common.messages.updated", model: "Isometry")
        else
          render :edit, status: :unprocessable_entity
        end
      end

      format.json do
        # For autosave, only exclude image parameters
        save_params = isometry_params.except(:rt_images, :vt_images, :pt_images)
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
            message: "Failed to save draft"
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @isometry.transaction do
      @isometry.update_columns(deleted: true)
    end
    redirect_to project_isometries_path(@project, locale: I18n.locale),
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
    isometries = @project.isometries.active
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
      page_number page_total
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
      :received_date, :pid_number, :pid_revision, :line_id, :dn,
      :revision_number, :page_number, :page_total, :pipe_class,
      :material, :system, :medium, :work_package_number, :revision_last,
      :dp, :dip, :isolation_required, :gmp, :gdp, :ped_category,
      :slope_if_needed, :rt, :vt2, :pt2, :pipe_length, :workshop_sn,
      :assembly_sn, :total_sn, :total_supports, :total_spools,
      :on_hold_status, :on_hold_comment, :notes, :qr_position, :draft,
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
