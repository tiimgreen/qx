class ChangeSollistFiltersToReferences < ActiveRecord::Migration[7.2]
  def change
    # Remove old string columns
    remove_column :projects, :sollist_filter1
    remove_column :projects, :sollist_filter2
    remove_column :projects, :sollist_filter3
    remove_column :projects, :progress_filter1
    remove_column :projects, :progress_filter2


    # Add new reference columns
    add_reference :projects, :sollist_filter1_sector, foreign_key: { to_table: :sectors }
    add_reference :projects, :sollist_filter2_sector, foreign_key: { to_table: :sectors }
    add_reference :projects, :sollist_filter3_sector, foreign_key: { to_table: :sectors }
    add_reference :projects, :progress_filter1_sector, foreign_key: { to_table: :sectors }
    add_reference :projects, :progress_filter2_sector, foreign_key: { to_table: :sectors }
  end
end
