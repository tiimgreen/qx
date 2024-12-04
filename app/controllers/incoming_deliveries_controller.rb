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

    @incoming_deliveries = base_scope
      .includes(:project, :work_location)
      .search_by_term(params[:search])
      .order(sort_column => sort_direction)
  end

  def show
    if @project && @incoming_delivery
      @delivery_items = @incoming_delivery.delivery_items.order(created_at: :desc)
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
    @incoming_delivery = @project.incoming_deliveries.build
    @incoming_delivery.assign_attributes(incoming_delivery_params.to_h)
    @incoming_delivery.user = current_user

    # Set on_hold_date when status is On Hold
    @incoming_delivery.on_hold_date = Time.current if @incoming_delivery.on_hold_status == "On Hold"

    if @incoming_delivery.save
      redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                  notice: t("common.messages.created", model: "Delivery")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if params[:complete_delivery]
      complete
    else
      # Handle delivery notes attachments first
      attach_delivery_notes if delivery_notes_present_in_params?

      # Process remaining attributes
      params_hash = remove_delivery_notes_params(incoming_delivery_params.to_h)

      # Set on_hold_date when status is On Hold
      if params_hash[:on_hold_status] == "On Hold"
        params_hash[:on_hold_date] = Time.current
      end

      if @incoming_delivery.update(params_hash)
        @incoming_delivery.update_completion_status
        redirect_to project_incoming_delivery_path(@project, @incoming_delivery),
                    notice: t("common.messages.updated", model: "Delivery")
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end


  def destroy
    @incoming_delivery.destroy
    redirect_to project_incoming_deliveries_path(@project),
                notice: t("common.messages.deleted", model: "Delivery")
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
      flash[:info] = "Please complete your existing deliveries before creating a new one"
    end
  end

  def authorize_view!
    unless current_user.can_view?("IncomingDelivery")
      flash[:alert] = "You don't have permission to view deliveries"
      redirect_to request.referer || projects_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("IncomingDelivery")
      flash[:alert] = "You don't have permission to create deliveries"
      redirect_to request.referer || projects_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("IncomingDelivery")
      flash[:alert] = "You don't have permission to update deliveries"
      redirect_to request.referer || projects_path
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("IncomingDelivery")
      flash[:alert] = "You don't have permission to delete deliveries"
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
end
