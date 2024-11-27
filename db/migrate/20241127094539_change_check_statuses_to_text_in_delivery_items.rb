class ChangeCheckStatusesToTextInDeliveryItems < ActiveRecord::Migration[7.2]
  def up
    change_column :delivery_items, :quantity_check_status, :text
    change_column :delivery_items, :dimension_check_status, :text
    change_column :delivery_items, :visual_check_status, :text
    change_column :delivery_items, :vt2_check_status, :text
    change_column :delivery_items, :ra_check_status, :text
  end

  def down
    change_column :delivery_items, :quantity_check_status, :boolean, default: false
    change_column :delivery_items, :dimension_check_status, :boolean, default: false
    change_column :delivery_items, :visual_check_status, :boolean, default: false
    change_column :delivery_items, :vt2_check_status, :boolean, default: false
    change_column :delivery_items, :ra_check_status, :boolean, default: false
  end
end
