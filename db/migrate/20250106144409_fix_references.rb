class FixReferences < ActiveRecord::Migration[7.2]
    def change
      add_foreign_key :test_packs, :projects
      add_foreign_key :test_packs, :work_locations
      add_foreign_key :test_packs, :users
      change_column_null :test_packs, :project_id, false

      add_foreign_key :work_preparations, :projects
      add_foreign_key :work_preparations, :work_locations
      add_foreign_key :work_preparations, :users
      change_column_null :work_preparations, :project_id, false

      add_foreign_key :transports, :projects
      add_foreign_key :transports, :users
      change_column_null :transports, :project_id, false

      add_foreign_key :site_deliveries, :projects
      add_foreign_key :site_deliveries, :users
      change_column_null :site_deliveries, :project_id, false

      add_foreign_key :site_assemblies, :projects
      add_foreign_key :site_assemblies, :users
      change_column_null :site_assemblies, :project_id, false

      add_foreign_key :on_sites, :projects
      add_foreign_key :on_sites, :users
      change_column_null :on_sites, :project_id, false

      add_foreign_key :test_packs, :projects
      add_foreign_key :test_packs, :work_locations
      add_foreign_key :test_packs, :users
      change_column_null :test_packs, :project_id, false
    end

    def down
      remove_foreign_key :test_packs, :projects
      remove_foreign_key :test_packs, :work_locations
      remove_foreign_key :test_packs, :users
      change_column_null :test_packs, :project_id, true

      remove_foreign_key :work_preparations, :projects
      remove_foreign_key :work_preparations, :work_locations
      remove_foreign_key :work_preparations, :users
      change_column_null :work_preparations, :project_id, true

      remove_foreign_key :transports, :projects
      remove_foreign_key :transports, :users
      change_column_null :transports, :project_id, true

      remove_foreign_key :site_deliveries, :projects
      remove_foreign_key :site_deliveries, :users
      change_column_null :site_deliveries, :project_id, true

      remove_foreign_key :site_assemblies, :projects
      remove_foreign_key :site_assemblies, :users
      change_column_null :site_assemblies, :project_id, true

      remove_foreign_key :on_sites, :projects
      remove_foreign_key :on_sites, :users
      change_column_null :on_sites, :project_id, true

      remove_foreign_key :test_packs, :projects
      remove_foreign_key :test_packs, :work_locations
      remove_foreign_key :test_packs, :users
      change_column_null :test_packs, :project_id, true
    end
end
