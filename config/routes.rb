# config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  devise_for :admins
  authenticate :admin do
    mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  end

  patch "/:locale", to: "application#switch_locale"

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get "/dashboard", to: "dashboard#index"

    # Add standalone route for material certificates index
    resources :material_certificates, only: [ :index ]

    resources :projects do
      resources :material_certificates, shallow: true
    end

    resources :incoming_deliveries do
      resources :delivery_items, shallow: true
      resources :missing_delivery_items, shallow: true
    end

    resources :delivery_items do
      resources :quality_inspections do
        member do
          delete :remove_image
        end
      end
      resource :roughness_measurement, shallow: true
    end

    resources :quality_inspections do
      resources :inspection_defects, shallow: true
      member do
        delete "remove_image/:image_id", action: :remove_image, as: :remove_image
      end
    end

    # Add standalone route for roughness measurements index
    resources :roughness_measurements, only: [ :index ]

    # Existing routes...
    get "up" => "rails/health#show", as: :rails_health_check
    get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
    get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
    root "home#index"
  end
end
