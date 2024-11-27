class DashboardController < ApplicationController
  before_action :authenticate_user!
  layout "dashboard_layout"

  def index
    @sectors = Sector.all
    # @sectors = current_user.sectors.distinct
  end

  private


end
