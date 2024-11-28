class RenameOnHoldReasonInIncomingDeliveries < ActiveRecord::Migration[7.2]
  def change
    rename_column :incoming_deliveries, :on_hold_reason, :on_hold_comment
    change_column :incoming_deliveries, :on_hold_status, :text
  end
end
