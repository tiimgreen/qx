RailsAdmin.config do |config|
  config.asset_source = :importmap

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :admin
  end
  config.current_user_method(&:current_admin)


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
        formatted_value do
          bindings[:object].user ? "#{bindings[:object].user.first_name} #{bindings[:object].user.last_name}" : "No user"
        end
      end
      field :sector
      field :permissions
      field :created_at
      field :updated_at
    end

    edit do
      field :user
      field :sector
      field :sector_permissions
    end
  end

  config.model "SectorPermission" do
    object_label_method do
      :custom_label
    end

    list do
      field :user_sector do
        formatted_value do
          if bindings[:object].user_sector
            user = bindings[:object].user_sector.user
            sector = bindings[:object].user_sector.sector
            "#{user.first_name} #{user.last_name} - #{sector.name}"
          else
            "No user sector"
          end
        end
      end
      field :permission
      field :created_at
      field :updated_at
    end

    edit do
      field :user_sector
      field :permission
    end
  end
end
