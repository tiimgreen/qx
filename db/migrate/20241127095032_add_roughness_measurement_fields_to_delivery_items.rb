class AddRoughnessMeasurementFieldsToDeliveryItems < ActiveRecord::Migration[7.2]
  def change
    add_column :delivery_items, :ra_date, :datetime
    add_column :delivery_items, :ra_value, :decimal, precision: 10, scale: 2
    add_column :delivery_items, :ra_parameters, :text
  end
end
