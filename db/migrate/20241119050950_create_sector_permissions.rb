class CreateSectorPermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :sector_permissions do |t|
      t.references :user_sector, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true
      t.timestamps
    end

    add_index :sector_permissions, [ :user_sector_id, :permission_id ], unique: true
  end
end
