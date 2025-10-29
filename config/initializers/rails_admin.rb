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
      field :email do
        searchable true
      end
      field :first_name do
        searchable true
      end
      field :last_name do
        searchable true
      end
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

    # Add custom action for managing permissions
    collection :manage_permissions do
      register_instance_option :link_icon do
        "fas fa-key"
      end

      register_instance_option :controller do
        proc do
          @users = User.all
          @permissions = Permission.all
          @resource_names = UserResourcePermission::RESOURCE_NAMES

          if request.post?
            user_id = params[:user_id]
            resource_name = params[:resource_name]
            permission_ids = Array(params[:permission_ids])

            if user_id.present? && resource_name.present?
              # Remove existing permissions for this user and resource
              UserResourcePermission.where(user_id: user_id, resource_name: resource_name).delete_all

              # Create new permissions
              permission_ids.each do |permission_id|
                UserResourcePermission.create!(
                  user_id: user_id,
                  resource_name: resource_name,
                  permission_id: permission_id
                )
              end

              respond_to do |format|
                format.html {
                  flash[:success] = t("admin.actions.manage_permissions.done")
                  redirect_to manage_permissions_path
                }
                format.json {
                  render json: { success: true }, status: :ok
                }
              end
            else
              respond_to do |format|
                format.html {
                  flash[:error] = "Please select a user and resource"
                  redirect_to manage_permissions_path
                }
                format.json {
                  render json: { error: "Please select a user and resource" }, status: :unprocessable_entity
                }
              end
            end
          else
            render action: @action.template_name
          end
        end
      end

      register_instance_option :http_methods do
        [ :get, :post ]
      end

      register_instance_option :visible? do
        true
      end

      register_instance_option :authorized? do
        true
      end
    end

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
        queryable true
        searchable [ :first_name, :last_name, :email ]
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
      field :vt_pictures
      field :on_hold_date
      field :on_hold_status
      field :qr_position
    end
  end

  config.model "ProjectSector" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :sector do
        queryable true
        searchable [ :key ]
      end
      field :created_at
      field :updated_at
    end

    edit do
      field :project
      field :sector
    end
  end

  config.model "ProjectUser" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :created_at
      field :updated_at
    end

    edit do
      field :project
      field :user
    end
  end

  config.model "WorkPreparation" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :isometry do
        queryable true
        searchable [ :line_id, :pid_number ]
      end
      field :work_location
      field :work_package_number
      field :on_hold_status
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :work_location
      field :user
      field :isometry
      field :work_package_number
      field :on_hold_status
      field :on_hold_comment
      field :completed
      field :completed_by
      field :work_preparation_type
      field :welding_batch_assignments
    end
  end

  config.model "Transport" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :work_package_number
      field :check_spools_status
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :user
      field :work_package_number
      field :check_spools_status
      field :check_spools_comment
      field :completed
      field :completed_by
    end
  end

  config.model "SiteDelivery" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :work_package_number
      field :check_spools_status
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :user
      field :work_package_number
      field :check_spools_status
      field :check_spools_comment
      field :completed
      field :completed_by
    end
  end

  config.model "Prefabrication" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :work_location
      field :work_package_number
      field :on_hold_status
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :work_location
      field :user
      field :work_package_number
      field :on_hold_status
      field :on_hold_comment
      field :completed
      field :completed_by
    end
  end

  config.model "OnSite" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :work_package_number
      field :on_hold_status
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :user
      field :work_package_number
      field :on_hold_status
      field :on_hold_comment
      field :completed
      field :completed_by
    end
  end

  config.model "FinalInspection" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :work_location
      field :work_package_number
      field :visual_check_status
      field :vt2_check_status
      field :pt2_check_status
      field :rt_check_status
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :work_location
      field :user
      field :work_package_number
      field :visual_check_status
      field :visual_check_comment
      field :vt2_check_status
      field :vt2_check_comment
      field :pt2_check_status
      field :pt2_check_comment
      field :rt_check_status
      field :rt_check_comment
      field :completed
      field :completed_by
    end
  end

  config.model "SiteAssembly" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :work_package_number
      field :on_hold_status
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :user
      field :work_package_number
      field :on_hold_status
      field :on_hold_comment
      field :completed
      field :completed_by
    end
  end

  config.model "PreWelding" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :work_location
      field :work_package_number
      field :on_hold_status
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :work_location
      field :user
      field :work_package_number
      field :on_hold_status
      field :on_hold_comment
      field :completed
      field :completed_by
    end
  end

  config.model "TestPack" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :user do
        queryable true
        searchable [ :email, :first_name, :last_name ]
      end
      field :work_location
      field :work_package_number
      field :on_hold_status
      field :test_pack_type
      field :completed
      field :created_at
    end

    edit do
      field :project
      field :work_location
      field :user
      field :work_package_number
      field :on_hold_status
      field :on_hold_comment
      field :test_pack_type
      field :completed
      field :completed_by
    end
  end

  config.model "ProjectProgressPlan" do
    list do
      field :project do
        queryable true
        searchable [ :name ]
      end
      field :work_type_sector do
        queryable true
        searchable [ :key ]
      end
      field :start_date
      field :end_date
      field :revision_number
      field :created_at
    end

    edit do
      field :project
      field :work_type_sector
      field :start_date
      field :end_date
      field :revision_number
    end
  end
end
