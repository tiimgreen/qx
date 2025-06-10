class AddApprovedForProductionToIsometries < ActiveRecord::Migration[7.2]
  def change
    add_column :isometries, :approved_for_production, :boolean,
               default: true, null: false
    add_index  :isometries, :approved_for_production
  end
end
