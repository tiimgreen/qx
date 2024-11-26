class UpdateDeliveryFields < ActiveRecord::Migration[7.2]
  def change
    # Remove old fields from incoming_deliveries
    remove_column :delivery_items, :completion_time, :datetime
    remove_column :delivery_items, :total_time, :datetime

    # Add on_hold to delivery_items
    add_column :delivery_items, :on_hold, :boolean, default: false
    add_column :delivery_items, :on_hold_reason, :text
    add_column :delivery_items, :on_hold_date, :datetime

    add_column :delivery_items, :completed, :boolean, default: false
    add_column :delivery_items, :total_time, :decimal, precision: 10, scale: 2

    add_column :incoming_deliveries, :on_hold, :boolean, default: false
    add_column :incoming_deliveries, :on_hold_reason, :text
    add_column :incoming_deliveries, :on_hold_date, :datetime
  end
end
