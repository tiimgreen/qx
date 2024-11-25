class SimplifySectorsTable < ActiveRecord::Migration[7.2]
  def change
    # Remove translation columns if they exist
    remove_column :sectors, :name if column_exists?(:sectors, :name)
    remove_column :sectors, :description if column_exists?(:sectors, :description)

    # Add key column if it doesn't exist
    add_column :sectors, :position, :integer unless column_exists?(:sectors, :position)
    add_column :sectors, :key, :string unless column_exists?(:sectors, :key)
    add_index :sectors, :key, unique: true unless index_exists?(:sectors, :key)
  end
end
