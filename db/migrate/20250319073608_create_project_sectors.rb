class CreateProjectSectors < ActiveRecord::Migration[7.2]
  def change
    create_table :project_sectors do |t|
      t.references :project, null: false, foreign_key: true
      t.string :sector

      t.timestamps
    end
  end
end
