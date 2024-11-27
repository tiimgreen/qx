class RenameNameToDeliveryNotePositionInDeliveryItems < ActiveRecord::Migration[7.2]
  def change
    rename_column :delivery_items, :name, :delivery_note_position
  end
end
