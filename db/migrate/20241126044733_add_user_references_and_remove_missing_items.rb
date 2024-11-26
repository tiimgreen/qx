class AddUserReferencesAndRemoveMissingItems < ActiveRecord::Migration[7.2]
  def change
    # Add user references
    add_reference :projects, :user, foreign_key: true
    add_reference :incoming_deliveries, :user, foreign_key: true

    # Remove missing_items table
    drop_table :missing_delivery_items do |t|
      t.integer "incoming_delivery_id", null: false
      t.integer "expected_quantity", null: false
      t.text "description", null: false
      t.string "order_line_reference"
      t.timestamps
      t.index ["incoming_delivery_id"], name: "index_missing_delivery_items_on_incoming_delivery_id"
    end
  end
end
