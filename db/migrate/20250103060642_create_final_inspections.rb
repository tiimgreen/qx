class CreateFinalInspections < ActiveRecord::Migration[6.0]
  def change
    create_table :final_inspections do |t|
      t.references :project, null: false, foreign_key: true
      t.references :work_location, foreign_key: true
      t.string :work_package_number
      t.text :on_hold_status
      t.text :on_hold_comment
      t.datetime :on_hold_date
      t.boolean :visual_check_status
      t.text :visual_check_comment
      t.text :vt2_check_status
      t.text :vt2_check_comment
      t.datetime :completed
      t.decimal :total_time, precision: 10, scale: 2
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
