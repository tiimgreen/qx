class CreatePreWeldings < ActiveRecord::Migration[7.2]
  def change
    create_table :pre_weldings do |t|
      t.references :project, null: false, foreign_key: true
      t.references :work_location, foreign_key: true
      t.string :work_package_number
      t.datetime :completed
      t.text :on_hold_status
      t.text :on_hold_comment
      t.datetime :on_hold_date
      t.references :user, foreign_key: true
      t.decimal :total_time, precision: 10, scale: 2

      t.timestamps
    end
  end
end
