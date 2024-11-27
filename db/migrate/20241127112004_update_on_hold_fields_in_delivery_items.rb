class UpdateOnHoldFieldsInDeliveryItems < ActiveRecord::Migration[7.2]
  def change
    # Change on_hold from boolean to text
    change_column :delivery_items, :on_hold, :text

    # Rename on_hold_reason to on_hold_comment
    rename_column :delivery_items, :on_hold_reason, :on_hold_comment
  end
end
