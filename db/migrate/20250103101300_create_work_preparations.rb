class CreateWorkPreparations < ActiveRecord::Migration[6.0]
  def change
    create_table :work_preparations do |t|
      t.integer :project_id, null: false
      t.integer :work_location_id
      t.string :work_package_number
      t.string :batch_number
      t.string :work_preparation_type
      t.datetime :completed
      t.text :on_hold_status
      t.text :on_hold_comment
      t.datetime :on_hold_date
      t.integer :user_id
      t.decimal :total_time, precision: 10, scale: 2

      t.timestamps
    end
  end
end
