class AddDeliveryItemsCountToIncomingDeliveries < ActiveRecord::Migration[7.2]
  def up
    add_column :incoming_deliveries, :delivery_items_count, :integer, default: 0, null: false

    # Update existing records
    execute <<-SQL
      UPDATE incoming_deliveries
      SET delivery_items_count = (
        SELECT COUNT(*)
        FROM delivery_items
        WHERE delivery_items.incoming_delivery_id = incoming_deliveries.id
      )
    SQL
  end

  def down
    remove_column :incoming_deliveries, :delivery_items_count
  end
end
