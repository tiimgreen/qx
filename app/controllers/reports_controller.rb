class ReportsController < ApplicationController
  before_action :set_project, only: [:isometries]

  def isometries
    @isometries = @project.isometries.includes(
      :final_inspection,
      :on_site,
      :pre_welding,
      :prefabrication,
      :site_assembly,
      :site_delivery,
      :test_pack,
      :transport,
      :work_preparation
    )
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
