class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  include Internationalization
  include Pagy::Backend

  skip_before_action :authenticate_user!, only: :switch_locale, raise: false
  skip_before_action :authorize_action!, only: :switch_locale, raise: false

  def default_url_options
    { locale: I18n.locale }
  end

  def switch_locale
    new_locale = params[:new_locale]
    if I18n.available_locales.map(&:to_s).include?(new_locale)
      session[:locale] = new_locale
      # Get the original referrer path without locale prefix
      original_path = URI(request.referrer).path.sub(/\A\/#{params[:locale]}/, "")
      # Redirect to the original path with new locale
      redirect_to "/#{new_locale}#{original_path}"
    else
      redirect_to root_path
    end
  end
end
