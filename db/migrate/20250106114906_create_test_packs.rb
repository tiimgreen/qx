class CreateTestPacks < ActiveRecord::Migration[6.0]
  def change
    create_table :test_packs do |t|
      t.integer :project_id
      t.integer :work_location_id
      t.string :work_package_number
      t.string :work_preparation_type
      t.string :test_pack_type
      t.string :dp_team
      t.string :operating_pressure
      t.string :dp_pressure
      t.string :dip_team
      t.string :dip_pressure
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
