class HomeController < ApplicationController
  before_action :dashboard_redirect, only: [ :index ]

  def index
  end

  private

  def dashboard_redirect
    if user_signed_in?
      redirect_to dashboard_path
    elsif guest_signed_in?
      redirect_to project_isometries_report_path(current_guest.project)
    end
  end
end
