class HomeController < ApplicationController
  before_action :dashboard_redirect, only: [ :index ]

  def index
  end

  private

  def dashboard_redirect
    redirect_to dashboard_path if user_signed_in?
  end
end
