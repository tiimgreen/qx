class RemoveLineIdUniquenessFromIsometries < ActiveRecord::Migration[7.2]
  def change
    # First remove the unique index
    remove_index :isometries, name: "index_isometries_on_line_id"

    # Add back a non-unique index for performance
    add_index :isometries, :line_id
  end
end
