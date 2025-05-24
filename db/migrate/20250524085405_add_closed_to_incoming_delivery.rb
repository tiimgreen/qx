class AddClosedToIncomingDelivery < ActiveRecord::Migration[7.2]
  def change
    add_column :incoming_deliveries, :closed, :boolean, default: false
  end
end
