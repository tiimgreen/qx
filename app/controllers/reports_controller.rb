class ReportsController < ApplicationController
  layout "dashboard_layout"
  before_action :authenticate_user_or_guest!
  before_action :set_project, only: [ :isometries ]
  before_action :authorize_view!

  def isometries
    @all_isometries = @project.isometries.includes(
      :work_preparations,
      :prefabrication,
      :pre_welding,
      :final_inspection,
      :transport,
      :site_delivery,
      :site_assembly,
      :on_site,
      :test_packs,
      :sector
    ).where(deleted: false, revision_last: true)

    # Filter by line_id
    @all_isometries = @all_isometries.where(line_id: params[:line_id]) if params[:line_id].present?

    # Filter by system
    @all_isometries = @all_isometries.where(system: params[:system]) if params[:system].present?

    # Filter by work_package_number
    @all_isometries = @all_isometries.where(work_package_number: params[:work_package_number]) if params[:work_package_number].present?

    # Filter by pipe_class
    @all_isometries = @all_isometries.where(pipe_class: params[:pipe_class]) if params[:pipe_class].present?

    # Filter by material
    @all_isometries = @all_isometries.where(material: params[:material]) if params[:material].present?

    # Filter by medium
    @all_isometries = @all_isometries.where(medium: params[:medium]) if params[:medium].present?

    # Store the filtered query for pagination
    @isometries = @all_isometries

    # Get unique values for filters
    @line_ids = @project.isometries.where(deleted: false, revision_last: true).distinct.pluck(:line_id).compact.sort
    @systems = @project.isometries.where(deleted: false, revision_last: true).distinct.pluck(:system).compact.sort
    @work_package_numbers = @project.isometries.where(deleted: false, revision_last: true).distinct.pluck(:work_package_number).compact.sort
    @pipe_classes = @project.isometries.where(deleted: false, revision_last: true).distinct.pluck(:pipe_class).compact.sort
    @materials = @project.isometries.where(deleted: false, revision_last: true).distinct.pluck(:material).compact.sort
    @mediums = @project.isometries.where(deleted: false, revision_last: true).distinct.pluck(:medium).compact.sort

    # Add pagination
    @pagy, @isometries = pagy(@isometries, items: params[:per_page] || 25)

    # Get the sector models for the view
    base_sector_models = Sector::QR_SECTOR_MODELS.reject { |s| s == "isometry" }

    @sector_models = if @project.workshop?
      # For workshop projects, only show sectors from project_sectors
      project_sector_keys = @project.project_sectors.pluck(:sector)
      base_sector_models.select { |s| project_sector_keys.include?(s) }
    else
      base_sector_models
    end

    # Calculate total pipe length and other metrics
    @total_pipe_length = @all_isometries.sum(:pipe_length)
    @total_isometries = @all_isometries.count

    # Calculate sector completions with workshop project handling
    @sector_completions = {}
    @sector_models.each do |sector|
      completed_isometries = if sector == "work_preparation"
        @all_isometries.select { |iso| WorkPreparation.completed_for?(iso) }
      elsif sector == "test_pack"
        @all_isometries.select { |iso| TestPack.completed_for?(iso) }
      else
        @all_isometries.select { |iso| iso.send(sector)&.completed? }
      end

      completed_pipe_length = completed_isometries.sum(&:pipe_length)

      @sector_completions[sector] = {
        completed_count: completed_isometries.size,
        count_percentage: (@all_isometries.size > 0 ? (completed_isometries.size * 100.0 / @all_isometries.size).round : 0),
        completed_meters: completed_pipe_length,
        meters_percentage: (@total_pipe_length > 0 ? (completed_pipe_length * 100.0 / @total_pipe_length).round : 0)
      }
    end
  end

  private

  def authenticate_user_or_guest!
    unless user_signed_in? || guest_signed_in?
      redirect_to root_path, alert: t("common.messages.not_authorized")
    end
  end

  def authorize_view!
    unless can_view_project?
      redirect_to root_path, alert: t("common.messages.not_authorized")
    end
  end

  def can_view_project?
    return false unless user_signed_in? || guest_signed_in?

    # For guests, check if they have access to this project
    current_guest&.project_id == @project.id || current_user&.projects&.exists?(@project.id)
  end

  def set_project
    @project = Project.find(params[:project_id])
  end
end
