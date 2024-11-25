class AddQualityControlFieldsToDeliveryItems < ActiveRecord::Migration[7.2]
  def change
    add_column :delivery_items, :name, :string
    add_column :delivery_items, :actual_quantity, :integer
    add_column :delivery_items, :target_quantity, :integer
    add_column :delivery_items, :quantity_check_status, :boolean, default: false  # For SOLL-IST Passed/Failed
    add_column :delivery_items, :quantity_check_comment, :text
    add_column :delivery_items, :dimension_check_status, :boolean, default: false # For Dimension Passed/Failed
    add_column :delivery_items, :dimension_check_comment, :text
    add_column :delivery_items, :visual_check_status, :boolean, default: false   # For Visuelle Prüfung
    add_column :delivery_items, :visual_check_comment, :text
    add_column :delivery_items, :vt2_check_status, :boolean, default: false      # For VT2
    add_column :delivery_items, :vt2_check_comment, :text        # For VT2 Comment
    add_column :delivery_items, :ra_check_status, :boolean, default: false       # For Ra
    add_column :delivery_items, :ra_check_comment, :text

    add_column :delivery_items, :completion_time, :datetime     # Lieferschein Komplett Stop
    add_column :delivery_items, :total_time, :datetime           # Zeit Total in minutes

    add_reference :delivery_items, :user, null: true, index: true
    remove_column :delivery_items, :quantity_received, :integer
  end
end
