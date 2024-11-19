class CreateMissingDeliveryItems < ActiveRecord::Migration[7.2]
  def change
    create_table :missing_delivery_items do |t|
      t.belongs_to :incoming_delivery, null: false, foreign_key: true
      t.integer :expected_quantity, null: false
      t.text :description, null: false
      t.string :order_line_reference

      t.timestamps
    end
  end
end
