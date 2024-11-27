class RenameOnHoldToOnHoldStatus < ActiveRecord::Migration[7.2]
  def change
    rename_column :delivery_items, :on_hold, :on_hold_status
    rename_column :incoming_deliveries, :on_hold, :on_hold_status
  end
end
