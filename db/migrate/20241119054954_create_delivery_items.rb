class CreateDeliveryItems < ActiveRecord::Migration[7.2]
  def change
    create_table :delivery_items do |t|
      t.belongs_to :incoming_delivery, null: false  # Must belong to a delivery
      t.string :tag_number                         # Might be assigned later
      t.string :batch_number, null: false          # Required for traceability
      t.integer :quantity_received, null: false    # Must know quantity
      t.string :item_description                   # Optional details
      t.text :specifications                       # Optional technical specs, will store JSON as text

      t.timestamps
    end

    add_index :delivery_items, [ :incoming_delivery_id, :tag_number ],
              unique: true,
              where: "tag_number IS NOT NULL"  # Partial index for non-null tag numbers
    add_index :delivery_items, :batch_number
  end
end
