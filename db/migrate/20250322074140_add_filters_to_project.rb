class AddFiltersToProject < ActiveRecord::Migration[7.2]
  def change
    add_column :projects, :sollist_filter1, :string, default: 'isometry'
    add_column :projects, :sollist_filter2, :string
    add_column :projects, :sollist_filter3, :string
    add_column :projects, :progress_filter1, :string
    add_column :projects, :progress_filter2, :string
  end
end
