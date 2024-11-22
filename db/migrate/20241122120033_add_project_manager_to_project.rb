class AddProjectManagerToProject < ActiveRecord::Migration[7.2]
  def change
    add_column :projects, :project_manager, :string
    add_column :projects, :client_name, :string
  end
end
