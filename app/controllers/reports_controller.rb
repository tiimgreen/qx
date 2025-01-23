class ReportsController < ApplicationController
  before_action :set_project, only: [ :isometries ]

  def isometries
    @isometries = @project.isometries.includes(
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
    @isometries = @isometries.where(line_id: params[:line_id]) if params[:line_id].present?

    # Filter by system
    @isometries = @isometries.where(system: params[:system]) if params[:system].present?

    # Filter by work_package_number
    @isometries = @isometries.where(work_package_number: params[:work_package_number]) if params[:work_package_number].present?

    # Filter by pipe_class
    @isometries = @isometries.where(pipe_class: params[:pipe_class]) if params[:pipe_class].present?

    # Filter by material
    @isometries = @isometries.where(material: params[:material]) if params[:material].present?

    # Filter by medium
    @isometries = @isometries.where(medium: params[:medium]) if params[:medium].present?

    # Get unique values for dropdowns
    @line_ids = @project.isometries.distinct.pluck(:line_id).compact.sort
    @systems = @project.isometries.distinct.pluck(:system).compact.sort
    @work_package_numbers = @project.isometries.distinct.pluck(:work_package_number).compact.sort
    @pipe_classes = @project.isometries.distinct.pluck(:pipe_class).compact.sort
    @materials = @project.isometries.distinct.pluck(:material).compact.sort
    @mediums = @project.isometries.distinct.pluck(:medium).compact.sort

    # Get the sector models for the view
    @sector_models = Sector::QR_SECTOR_MODELS.reject { |s| s == "isometry" }
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
