class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  include Internationalization

  def default_url_options
    { locale: I18n.locale }
  end

  def switch_locale
  I18n.locale = params[:locale]
    redirect_back(fallback_location: root_path)
  end
end
