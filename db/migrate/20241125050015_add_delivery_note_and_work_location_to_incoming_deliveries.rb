class AddDeliveryNoteAndWorkLocationToIncomingDeliveries < ActiveRecord::Migration[7.2]
  def change
    add_column :incoming_deliveries, :delivery_note_number, :string
    add_reference :incoming_deliveries, :work_location, foreign_key: true

    add_index :incoming_deliveries, :delivery_note_number
  end
end
