# config/routes.rb
Rails.application.routes.draw do
  # Add specific route for locale switching outside the locale scope
  post "/switch_locale/:new_locale", to: "application#switch_locale", as: :switch_locale

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get "/dashboard", to: "dashboard#index"

    devise_for :users
    devise_for :admins
    authenticate :admin do
      mount RailsAdmin::Engine => "/admin", as: "rails_admin"
    end
    # Add standalone route for material certificates index
    resources :material_certificates do
      collection do
        get :search
        get :search, as: :search_material_certificates
      end
    end

    resources :projects do
      resources :incoming_deliveries do
        resources :delivery_items do
          delete "delete_image", on: :member
        end
      end
      resources :isometries do
        member do
          delete :delete_image
          delete :remove_certificate
          get :download_welding_report
          post :create_revision
        end
        post :new_page, on: :member
        resources :weldings
      end
    end

    resources :incoming_deliveries, only: [] do  # Changed from full resources to only: []
      resources :delivery_items, shallow: true
    end

    resources :delivery_items do
      delete "delete_image", on: :member
    end

    # Existing routes...
    get "up" => "rails/health#show", as: :rails_health_check
    get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
    get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
    root "home#index"
  end
end
