RailsAdmin.config do |config|
  config.asset_source = :importmap

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :admin
  end
  config.current_user_method(&:current_admin)

  # Set the current locale for RailsAdmin
  config.main_app_name = proc { |controller|
    [
      I18n.t("admin.site_title", default: "Admin"),
      I18n.t("admin.site_title_main", default: "Site")
    ]
  }

  # Configure RailsAdmin to use the current locale
  config.parent_controller = "::ApplicationController"

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  # Exclude IsometryDocument model
  config.model "IsometryDocument" do
    visible false
  end

  config.model "User" do
    list do
      field :email
      field :first_name
      field :last_name
      field :admin
      field :can_close_incoming_delivery
      field :active
      field :created_at
    end

    edit do
      field :email
      field :first_name
      field :last_name
      field :phone
      field :address
      field :city
      field :active
      field :admin
      field :can_close_incoming_delivery
      field :password
      field :password_confirmation
    end
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end


  config.model "UserSector" do
    object_label_method do
      :custom_label
    end

    list do
      field :user do
      end
      field :sector
      field :created_at
      field :updated_at
    end

    edit do
      field :user
      field :sector
    end
  end

  config.model "Isometry" do
    edit do
      field :project
      field :sector
      field :user
      field :weldings
      field :isometry_documents
      field :material_certificates do
        associated_collection_cache_all false
        associated_collection_scope do
          proc { |scope| scope.search_by_term(query) }
        end
      end
      field :received_date
      field :pid_number
      field :pid_revision
      field :line_id
      field :dn
      field :revision_number
      field :revision_last
      field :page_number
      field :page_total
      field :medium
      field :pipe_length
      field :workshop_sn
      field :assembly_sn
      field :total_sn
      field :total_supports
      field :total_spools
      field :rt
      field :vt2
      field :pt2
      field :on_hold_date
      field :on_hold_status
      field :qr_position
    end
  end
end
