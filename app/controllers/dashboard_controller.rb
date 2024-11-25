class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_sector_access!
  layout "dashboard_layout"

  def index
    @sectors = Sector.all
    # @sectors = current_user.sectors.distinct
  end

  private

  def authorize_sector_access!
    @sector = Sector.find(params[:sector_id]) if params[:sector_id]

    unless @sector.nil? || can_access_sector?(@sector)
      flash[:error] = "You don't have permission to access this sector"
      redirect_to root_path
    end
  end

  def can_access_sector?(sector)
    current_user.sector_permissions.exists?(sector: sector)
  end

  def can_perform_action?(sector, action_code)
    current_user.sector_permissions.exists?(
      sector: sector,
      permission: Permission.find_by(code: action_code)
    )
  end
end
