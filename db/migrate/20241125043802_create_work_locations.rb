class CreateWorkLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :work_locations do |t|
      t.string :key           # Unique identifier/key
      t.string :name          # Optional custom name
      t.string :location_type # Our enum field
      t.text :description
      t.timestamps
    end
  end
end
