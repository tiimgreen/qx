class QrCodesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_isometry
  before_action :validate_user_sector

  def redirect
    sectors = current_user.sectors.select { |s| Sector::QR_SECTOR_MODELS.include?(s.key) }

    if sectors.empty?
      redirect_to root_path, alert: t("alerts.no_valid_sector")
    elsif sectors.count == 1
      handle_sector_redirect(sectors.first)
    else
      @sectors = sectors
      render :select_sector
    end
  end

  def select_sector
    sector = current_user.sectors.find_by(id: params[:sector_id])
    if sector && Sector::QR_SECTOR_MODELS.include?(sector.key)
      handle_sector_redirect(sector)
    else
      redirect_to root_path, alert: t("alerts.invalid_sector")
    end
  end

  private

  def set_isometry
    id = params[:isometry_id] || params[:id]
    @isometry = Isometry.find(id)
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("alerts.isometry_not_found")
  end

  def validate_user_sector
    unless current_user.sectors.any?
      redirect_to root_path, alert: t("alerts.no_sector_assigned")
    end
  end

  def handle_sector_redirect(sector)
    if sector.key == "isometry"
      redirect_to project_isometry_path(@isometry.project, @isometry)
      return
    end

    if sector.key == "work_preparation"
      items = WorkPreparation.where(isometry: @isometry)
      if items.count == 1
        redirect_to edit_project_work_preparation_path(@isometry.project, items.first)
      else
        @sectors = [ sector ]
        render :select_sector
      end
      return
    end

    model_class = sector.key.classify.constantize rescue nil
    return redirect_to root_path, alert: t("alerts.invalid_sector_model") unless model_class

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
    redirect_to root_path, alert: t("alerts.qr_processing_error")
  end
end
