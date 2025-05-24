class AddCanCloseIncomingDeliveryToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :can_close_incoming_delivery, :boolean, default: false
  end
end
