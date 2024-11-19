class CreateRoughnessMeasurements < ActiveRecord::Migration[7.2]
  def change
    create_table :roughness_measurements do |t|
      t.belongs_to :delivery_item, null: false
      t.datetime :measurement_date, null: false
      t.decimal :measured_value, null: false, precision: 10, scale: 2
      t.text :measurement_parameters              # Changed from jsonb to text
      t.text :notes

      t.timestamps
    end
  end
end
