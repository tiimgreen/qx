class AddArchivedToProjects < ActiveRecord::Migration[7.2]
  def change
    add_column :projects, :archived, :boolean, default: false, null: false
    add_index  :projects, :archived
  end
end
