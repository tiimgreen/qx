class RemoveBatchNumberFromWorkPreparations < ActiveRecord::Migration[7.2]
  def change
    remove_column :work_preparations, :batch_number, :string
  end
end
