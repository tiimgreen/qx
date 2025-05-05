class IncomingDeliveriesController < ApplicationController
  include CompletableController

  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_incoming_delivery, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_action!

  def index
    base_scope = if @project
      @project.incoming_deliveries
    else
      IncomingDelivery.all
    end

    sort_column = sort_params || "delivery_date"
    sort_direction = params[:direction] || "desc"

    @pagy, @incoming_deliveries = pagy(
      base_scope
        .includes(:project, :work_location)
        .search_by_term(params[:search])
        .order(sort_column => sort_direction)
    )
  end

  def show
    if @project && @incoming_delivery
      @delivery_items = @incoming_delivery.delivery_items
                                        .includes(:user, :project)
                                        .sorted_by(params[:sort], params[:direction])

      respond_to do |format|
        format.html
        format.pdf { render pdf: "delivery_note_#{@incoming_delivery.delivery_note_number}" }
      end
    else
      flash[:alert] = "Delivery not found"
      redirect_to project_incoming_deliveries_path(@project)
    end
  end

  def new
    @incoming_delivery = @project ? @project.incoming_deliveries.build : IncomingDelivery.new
  end

  def edit
  end

  def create
    delivery_params = incoming_delivery_params
    uploaded_files = delivery_params.delete(:delivery_notes)

    @incoming_delivery = @project ? @project.incoming_deliveries.build(delivery_params) : IncomingDelivery.new(delivery_params)
    @incoming_delivery.user = current_user

    # Set on_hold_date when status is On Hold
    @incoming_delivery.on_hold_date = Time.current if @incoming_delivery.on_hold_status == "On Hold"

    if @incoming_delivery.save
      begin
        if uploaded_files.present?
          uploaded_files.each do |file|
            handle_docuvita_delivery_note_upload(@incoming_delivery, file)
          end
        end

        redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                    notice: t("common.messages.created", model: "Delivery")
      rescue StandardError => e
        # Show error and rollback
        @incoming_delivery.destroy
        flash.now[:alert] = t(".upload_error", message: e.message)
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if params[:complete_delivery]
      complete
    else
      delivery_params = incoming_delivery_params
      uploaded_files = delivery_params.delete(:delivery_notes)

      # Handle delivery notes attachments first
      # attach_delivery_notes if delivery_notes_present_in_params?

      # Process remaining attributes
      params_hash = remove_delivery_notes_params(delivery_params)

      # Set on_hold_date when status is On Hold
      if params_hash[:on_hold_status] == "On Hold"
        params_hash[:on_hold_date] = Time.current
      end

      if @incoming_delivery.update(params_hash)
        begin
          if uploaded_files.present?
            uploaded_files.each do |file|
              handle_docuvita_delivery_note_upload(@incoming_delivery, file)
            end
          end

          @incoming_delivery.update_completion_status
          redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                      notice: t("common.messages.updated", model: "Delivery")
        rescue StandardError => e
          flash.now[:alert] = t(".upload_error", message: e.message)
          render :edit, status: :unprocessable_entity
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @incoming_delivery.destroy
    redirect_to project_incoming_deliveries_path(@project), notice: t(".success")
  end

  def complete
    # unless @incoming_delivery.can_complete?
    #   flash[:alert] = "Please complete all delivery items before completing the delivery"
    #   redirect_to project_incoming_delivery_path(@project, @incoming_delivery)
    # end

    complete_resource(
      @incoming_delivery,
      project_incoming_delivery_path(@project, @incoming_delivery),
      incoming_delivery_params
    )
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

    if current_user.has_pending_deliveries?("IncomingDelivery", @project.id)
      flash[:info] =  t("common.messages.pending_deliveries")
    end
  end

  def authorize_view!
    unless current_user.can_view?("IncomingDelivery")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: IncomingDelivery.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("IncomingDelivery")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: IncomingDelivery.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("IncomingDelivery")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: IncomingDelivery.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("IncomingDelivery")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: IncomingDelivery.model_name.human)
      redirect_to request.referer || projects_path
    end
  end

  def sort_params
    allowed_columns = %w[
      work_location_id
      delivery_note_number
      order_number
      delivery_date
      supplier_name
      on_hold_status
      completed
      delivery_items_count
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

  def set_incoming_delivery
    return unless @project
    @incoming_delivery = @project.incoming_deliveries.find_by(id: params[:id])
    unless @incoming_delivery
      flash[:alert] = "Delivery not found"
      redirect_to project_incoming_deliveries_path(@project)
    end
  end

  def incoming_delivery_params
    params.require(:incoming_delivery).permit(
      :project_id,
      :delivery_date,
      :order_number,
      :supplier_name,
      :notes,
      :work_location_id,
      :delivery_note_number,
      :completed,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :total_time,
      *completable_params,
      delivery_notes: []
    )
  end

  def delivery_notes_present_in_params?
    params.dig(:incoming_delivery, :delivery_notes)&.any?
  end

  def attach_delivery_notes
    params[:incoming_delivery][:delivery_notes].each do |note|
      @incoming_delivery.delivery_notes.attach(note)
    end
  end

  def remove_delivery_notes_params(params_hash)
    params_hash.except(:delivery_notes)
  end

  # Handles uploading the delivery note file to Docuvita
  def handle_docuvita_delivery_note_upload(delivery, file)
    unless file.is_a?(ActionDispatch::Http::UploadedFile)
      Rails.logger.warn("Skipping Docuvita upload: Invalid file parameter type.")
      return # Or raise an error if file is mandatory
    end

    # Delegate to the model instance method for actual upload logic
    delivery.upload_delivery_note_to_docuvita(file, file.original_filename)
  end
end
