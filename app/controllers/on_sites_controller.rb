class OnSitesController < ApplicationController
    layout "dashboard_layout"
    include CompletableController
    before_action :authenticate_user!
    before_action :set_project
    before_action :set_isometry, except: [ :index ]
    before_action :set_on_site, only: [ :show, :edit, :update, :destroy, :complete ]
    before_action :authorize_action!

    def index
      sort_column = sort_params || "created_at"
      sort_direction = params[:direction] || "desc"

      @pagy, @on_sites = pagy(
        @project.on_sites.search_by_term(params[:search])
              .order(sort_column => sort_direction)
      )
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

      # Handle image attachments separately
      attach_on_hold_images if params.dig(:on_site, :on_hold_images).present?

      if @on_site.save
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
      attach_on_hold_images if params.dig(:on_site, :on_hold_images).present?

      if @on_site.update(on_site_params_without_images)
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
        work_package_number
        on_hold_status
        completed
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
        on_hold_images: []
      )
    end

    def on_site_params_without_images
      on_site_params.except(:on_hold_images)
    end

    def attach_on_hold_images
      return unless params.dig(:on_site, :on_hold_images).present?

      params[:on_site][:on_hold_images].each do |image|
        @on_site.on_hold_images.attach(image)
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
