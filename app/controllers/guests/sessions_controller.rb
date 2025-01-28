class Guests::SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    super do |guest|
      # After successful sign in, redirect to the guest's project page
      return redirect_to project_isometries_report_path(guest.project) if guest.persisted?
    end
  end
end
