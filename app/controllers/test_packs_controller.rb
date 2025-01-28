class TestPacksController < ApplicationController
  layout "dashboard_layout"
  include CompletableController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_isometry, except: [ :index ]
  before_action :set_test_pack, only: [ :show, :edit, :update, :destroy, :complete ]
  before_action :authorize_action!

  def index
    base_scope = @project.test_packs.includes(:work_location, isometry: [ :project, :sector ])

    if params[:search].present?
      base_scope = base_scope.search_by_term(params[:search])
    end

    sort_column = sort_params || "line_id"  # Default sort by line_id
    sort_direction = params[:direction] || "asc"

    # If using default sort (line_id), add secondary sorts for page_number and id
    @test_packs = if sort_column == "line_id"
      base_scope.joins(:isometry)
               .reorder("isometries.line_id #{sort_direction}")
               .order("isometries.page_number #{sort_direction}")
               .order("isometries.id ASC")  # Always show older isometries first within same line/page
    else
      base_scope.reorder(sort_column => sort_direction)
    end

    @pagy, @test_packs = pagy(@test_packs)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @test_pack }
    end
  end

  def new
    @test_pack = @project.test_packs.new
    if @isometry
      @test_pack.work_package_number = @isometry.work_package_number
    end
  end

  def edit
    @isometry = @test_pack.isometry
  end

  def create
    @test_pack = @project.test_packs.new(test_pack_params_without_images)
    @test_pack.user = current_user

    # Handle image attachments separately
    attach_images(:on_hold_images) if params.dig(:test_pack, :on_hold_images).present?

    if @test_pack.save
      redirect_to project_test_pack_path(@project, @test_pack),
                      notice: t("common.messages.success.created", model: "TestPack")
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "test_pack_form",
            partial: "form",
            locals: { project: @project, test_pack: @test_pack }
          )
        }
      end
    end
  end

  def update
    on_hold_params(params)
    attach_images(:on_hold_images) if params.dig(:test_pack, :on_hold_images).present?

    if @test_pack.update(test_pack_params_without_images)
      redirect_to project_test_pack_path(@project, @test_pack),
                      notice: t("common.messages.updated", model: "TestPack")
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "test_pack_form",
            partial: "form",
            locals: { project: @project, test_pack: @test_pack }
          )
        }
      end
    end
  end

  def complete
    complete_resource(
      @test_pack,
      project_test_pack_path(@project, @test_pack),
      {}  # No need for params, completion values will be set by complete_resource
    )
  end

  def destroy
    @test_pack.destroy
    redirect_to project_test_packs_path(@project, locale: I18n.locale),
                notice: t("common.messages.success.deleted", model: TestPack.model_name.human)
  end

  private

  def sort_params
    allowed_columns = %w[
      line_id work_package_number page_number
      created_at completed on_hold_status test_pack_type
    ]
    params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
  end

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_test_pack
    @test_pack = @project.test_packs.find(params[:id])
  end

  def set_isometry
    isometry_id = if params[:test_pack].present?
      params[:test_pack][:isometry_id]
    else
      params[:isometry_id]
    end
    @isometry = @project.isometries.find(isometry_id) if isometry_id.present?
  end

  def test_pack_params
    return {} unless params[:test_pack].present?

    params.require(:test_pack).permit(
      :work_location_id,
      :work_package_number,
      :test_pack_type,
      :dp_team,
      :operating_pressure,
      :dp_pressure,
      :dip_team,
      :dip_pressure,
      :on_hold_status,
      :on_hold_comment,
      :on_hold_date,
      :batch_number,
      :work_preparation_type,
      :completed,
      :isometry_id,
      :total_time,
      :project_id,
      :one_test,
      on_hold_images: []
    )
  end

  def test_pack_params_without_images
    test_pack_params.except(:on_hold_images)
  end

  def attach_images(image_type)
    return unless params.dig(:test_pack, image_type).present?

    params[:test_pack][image_type].each do |image|
      @test_pack.send(image_type).attach(image)
    end
  end

  def on_hold_params(params)
    if params[:test_pack][:on_hold_status] == "On Hold"
      params[:test_pack][:on_hold_date] = Time.current
      params[:test_pack][:completed] = nil
    else
      params[:test_pack][:on_hold_date] = nil
      params[:test_pack][:on_hold_comment] = nil
    end
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
    unless current_user.can_view?("TestPack")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: TestPack.model_name.human)
      redirect_to request.referer || root_path
    end
  end

  def authorize_create!
    unless current_user.can_create?("TestPack")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: TestPack.model_name.human)
      redirect_to request.referer || test_packs_path
    end
  end

  def authorize_edit!
    unless current_user.can_edit?("TestPack")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: TestPack.model_name.human)
      redirect_to request.referer || test_pack_path(@test_pack)
    end
  end

  def authorize_destroy!
    unless current_user.can_delete?("TestPack")
      flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: TestPack.model_name.human)
      redirect_to request.referer || test_pack_path(@test_pack)
    end
  end
end
