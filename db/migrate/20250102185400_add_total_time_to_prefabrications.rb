class AddTotalTimeToPrefabrications < ActiveRecord::Migration[6.0]
  def change
    add_column :prefabrications, :total_time, :decimal, precision: 10, scale: 2
  end
end
