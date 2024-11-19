class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.string :project_number, null: false
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :projects, :project_number, unique: true
  end
end
