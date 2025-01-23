class RenameProjectManagerToProjectManagerClientAndAddProjectManagerQualinoxAndProjectEnd < ActiveRecord::Migration[7.2]
  def change
    rename_column :projects, :project_manager, :project_manager_client
    add_column :projects, :project_manager_qualinox, :string
    add_column :projects, :project_end, :datetime
  end
end
