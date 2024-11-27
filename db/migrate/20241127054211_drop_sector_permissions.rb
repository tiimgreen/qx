class DropSectorPermissions < ActiveRecord::Migration[7.2]
  def up
    drop_table :sector_permissions if table_exists?(:sector_permissions)
  end

  def down
    # Add this if you want to be able to rollback the migration
    # Include the original table structure
    create_table :sector_permissions do |t|
      t.references :sector, foreign_key: true
      t.references :permission, foreign_key: true

      t.timestamps
    end
  end
end
