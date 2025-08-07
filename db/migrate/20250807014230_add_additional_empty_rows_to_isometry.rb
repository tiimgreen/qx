class AddAdditionalEmptyRowsToIsometry < ActiveRecord::Migration[7.2]
  def change
    add_column :isometries, :additional_empty_rows, :integer, default: 0
  end
end
