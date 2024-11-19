Rails.application.routes.draw do
  devise_for :users
  devise_for :admins
  authenticate :admin do
    mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  end

  patch "/:locale", to: "application#switch_locale"

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get "/dashboard", to: "dashboard#index"

    # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
    # Can be used by load balancers and uptime monitors to verify that the app is live.
    get "up" => "rails/health#show", as: :rails_health_check

    # Render dynamic PWA files from app/views/pwa/*
    get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
    get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

    # Defines the root path route ("/")
    root "home#index"
  end
end
