class DashboardController < ApplicationController
  layout "dashboard_layout"
  before_action :authenticate_user!

  def index
    @sectors = Sector.all
    # @sectors = current_user.sectors.distinct
  end

  private
end
