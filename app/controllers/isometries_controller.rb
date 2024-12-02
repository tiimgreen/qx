class IsometriesController < ApplicationController
  include CompletableController

  layout "dashboard_layout"
  before_action :set_project
  before_action :set_isometry, only: [ :show, :edit, :update, :destroy ]
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
      .includes(:project, :sector)
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

    # Then update other attributes
    if @isometry.update(isometry_params)
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

  private

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
      :dn1,
      :dn2,
      :dn3,
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
      :test_pack_number,
      isometry_documents_attributes: [ :id, :qr_position, :_destroy ]
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
