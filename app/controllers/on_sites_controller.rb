class OnSitesController < ApplicationController
    layout "dashboard_layout"
    include CompletableController
    before_action :authenticate_user!
    before_action :set_project
    before_action :set_isometry, except: [ :index ]
    before_action :set_on_site, only: [ :show, :edit, :update, :destroy, :complete ]
    before_action :authorize_action!

    def index
      base_scope = @project.on_sites.includes(isometry: [ :project, :sector ])

      if params[:search].present?
        base_scope = base_scope.search_by_term(params[:search])
      end

      sort_column = sort_params || "line_id"  # Default sort by line_id
      sort_direction = params[:direction] || "asc"

      # If using default sort (line_id), add secondary sorts for page_number and id
      @on_sites = if sort_column == "line_id"
        base_scope.joins(:isometry)
                 .reorder("isometries.line_id #{sort_direction}")
                 .order("isometries.page_number #{sort_direction}")
                 .order("isometries.id ASC")  # Always show older isometries first within same line/page
      else
        base_scope.reorder(sort_column => sort_direction)
      end

      @pagy, @on_sites = pagy(@on_sites)
    end

    def show
      respond_to do |format|
        format.html
        format.json { render json: @on_site }
      end
    end

    def new
      @on_site = @project.on_sites.new
      if @isometry
        @on_site.work_package_number = @isometry.work_package_number
      end
    end

    def edit
      @isometry = @on_site.isometry
    end

    def create
      @on_site = @project.on_sites.new(on_site_params_without_images)
      @on_site.user = current_user

      if @on_site.save
        handle_docuvita_image_uploads(@on_site)
        redirect_to project_on_site_path(@project, @on_site),
                    notice: t("common.messages.success.created", model: OnSite.model_name.human)
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace(
              "on_site_form",
              partial: "form",
              locals: { project: @project, on_site: @on_site }
            )
          }
        end
      end
    end

    def update
      on_hold_params(params)

      if @on_site.update(on_site_params_without_images)
        handle_docuvita_image_uploads(@on_site)
        redirect_to project_on_site_path(@project, @on_site),
                    notice: t("common.messages.success.updated", model: OnSite.model_name.human)
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream {
            render turbo_stream: turbo_stream.replace(
              "on_site_form",
              partial: "form",
              locals: { project: @project, on_site: @on_site }
            )
          }
        end
      end
    end

    def complete
      complete_resource(
        @on_site,
        project_on_site_path(@project, @on_site),
        {}  # No need for params, completion values will be set by complete_resource
      )
    end

    def destroy
      @on_site.destroy
      redirect_to project_on_sites_path(@project), notice: t("common.messages.success.deleted", model: OnSite.model_name.human)
    end

    private
    def sort_params
      allowed_columns = %w[
        line_id work_package_number page_number
        created_at completed on_hold_status
      ]
      params[:sort].to_s if allowed_columns.include?(params[:sort].to_s)
    end

    def set_project
      @project = Project.find(params[:project_id])
    end

    def set_on_site
      @on_site = @project.on_sites.find(params[:id])
    end

    def set_isometry
      if params[:on_site].present? && params[:on_site][:isometry_id].present?
        @isometry = @project.isometries.find(params[:on_site][:isometry_id])
      end
    end

    def on_site_params
      return {} unless params[:on_site].present?

      params.require(:on_site).permit(
        :work_package_number,
        :on_hold_status,
        :on_hold_comment,
        :on_hold_date,
        :completed,
        :isometry_id,
        :total_time,
        on_hold_images: [],
        on_site_images: []
      )
    end

    def on_site_params_without_images
      params.require(:on_site).permit(
        :work_package_number,
        :on_hold_status,
        :on_hold_comment,
        :on_hold_date,
        :isometry_id,
        :project_id
      )
    end

    def handle_docuvita_image_uploads(on_site)
      # Handle on-hold images
      if params.dig(:on_site, :on_hold_images).present?
        Array(params[:on_site][:on_hold_images]).each do |image|
          next unless image.is_a?(ActionDispatch::Http::UploadedFile)
          on_site.upload_image_to_docuvita(image, image.original_filename, "on_hold_image")
        end
      end

      # Handle regular images
      if params.dig(:on_site, :on_site_images).present?
        Array(params[:on_site][:on_site_images]).each do |image|
          next unless image.is_a?(ActionDispatch::Http::UploadedFile)
          on_site.upload_image_to_docuvita(image, image.original_filename, "on_site_image")
        end
      end
    end

    def on_hold_params(params)
      if params[:on_site][:on_hold_status] == "On Hold"
        params[:on_site][:on_hold_date] = Time.current
        params[:on_site][:completed] = nil
      else
        params[:on_site][:on_hold_date] = nil
        params[:on_site][:on_hold_comment] = nil
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
      unless current_user.can_view?("OnSite")
        flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.show"), model: OnSite.model_name.human)
        redirect_to request.referer || root_path
      end
    end

    def authorize_create!
      unless current_user.can_create?("OnSite")
        flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.new"), model: OnSite.model_name.human)
        redirect_to request.referer || on_sites_path
      end
    end

    def authorize_edit!
      unless current_user.can_edit?("OnSite")
        flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.edit"), model: OnSite.model_name.human)
        redirect_to request.referer || on_site_path(@on_site)
      end
    end

    def authorize_destroy!
      unless current_user.can_delete?("OnSite")
        flash[:alert] = t("common.messages.unauthorized", action: t("common.actions.delete"), model: OnSite.model_name.human)
        redirect_to request.referer || on_site_path(@on_site)
      end
    end
end
