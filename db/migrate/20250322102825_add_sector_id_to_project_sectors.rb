class AddSectorIdToProjectSectors < ActiveRecord::Migration[7.2]
  def change
    remove_column :project_sectors, :sector
    add_reference :project_sectors, :sector, null: false, foreign_key: true
  end
end
