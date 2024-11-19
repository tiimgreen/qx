class CreateIncomingDeliveries < ActiveRecord::Migration[7.2]
  def change
    create_table :incoming_deliveries do |t|
      t.belongs_to :project, null: false, foreign_key: true
      t.date :delivery_date, null: false
      t.string :order_number, null: false
      t.string :supplier_name, null: false
      t.text :notes

      t.timestamps
    end

    add_index :incoming_deliveries, :order_number
  end
end
