class CreateUserResourcePermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_resource_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true
      t.string :resource_name, null: false

      t.timestamps
    end

    add_index :user_resource_permissions, [ :user_id, :resource_name, :permission_id ],
              unique: true,
              name: 'index_user_resource_permissions_uniqueness'
  end
end
