class CreateInitialPermissions < ActiveRecord::Migration[7.2]
  def up
    Permission.create([
      { name: 'Can View', code: 'view' },
      { name: 'Can Create', code: 'create' },
      { name: 'Can Edit', code: 'edit' },
      { name: 'Can Delete', code: 'delete' }
    ])
  end

  def down
    # First remove any references to these permissions in sector_permissions
    execute("DELETE FROM sector_permissions WHERE permission_id IN (SELECT id FROM permissions)")
    # Then safely delete all permissions
    Permission.delete_all
  end
end
