class QrCodesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_isometry
  before_action :validate_user_sector

  def redirect
    sector = current_user.sectors.first
    handle_sector_redirect(sector)
  end

  private

  def set_isometry
    @isometry = Isometry.find(params[:isometry_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Isometry not found"
  end

  def validate_user_sector
    unless current_user.sectors.any?
      redirect_to root_path, alert: "No sector assigned to user"
    end
  end

  def handle_sector_redirect(sector)
    model_class = sector.key.classify.constantize rescue nil
    return redirect_to root_path, alert: "Invalid sector model" unless model_class

    record = model_class.find_by(isometry: @isometry)

    if record
      redirect_to send("edit_project_#{sector.key}_path", @isometry.project, record)
    else
      redirect_to send("new_project_#{sector.key}_path",
        @isometry.project,
        sector.key => {
          isometry_id: @isometry.id
        }
      )
    end
  rescue => e
    Rails.logger.error "Error in QR redirect: #{e.message}"
    redirect_to root_path, alert: "Error processing QR code"
  end
end
