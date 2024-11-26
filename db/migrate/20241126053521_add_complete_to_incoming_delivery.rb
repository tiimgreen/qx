class AddCompleteToIncomingDelivery < ActiveRecord::Migration[7.2]
  def change
    add_column :incoming_deliveries, :completed, :boolean, default: false
    add_column :incoming_deliveries, :total_time, :decimal, precision: 10, scale: 2
  end
end
