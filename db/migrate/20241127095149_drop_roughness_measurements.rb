class DropRoughnessMeasurements < ActiveRecord::Migration[7.2]
  def up
    drop_table :roughness_measurements
  end

  def down
    create_table :roughness_measurements do |t|
      t.integer :delivery_item_id, null: false
      t.datetime :measurement_date, null: false
      t.decimal :measured_value, precision: 10, scale: 2, null: false
      t.text :measurement_parameters
      t.text :notes
      t.timestamps
      t.index [ "delivery_item_id" ], name: "index_roughness_measurements_on_delivery_item_id"
    end
  end
end
