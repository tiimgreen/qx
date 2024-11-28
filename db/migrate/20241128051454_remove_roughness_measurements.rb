class RemoveRoughnessMeasurements < ActiveRecord::Migration[7.2]
  def change
    drop_table :roughness_measurements, if_exists: true
  end
end
