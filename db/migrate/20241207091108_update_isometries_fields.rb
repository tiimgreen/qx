class UpdateIsometriesFields < ActiveRecord::Migration[7.2]
  def change
    # Remove string fields
    remove_column :isometries, :dn1, :string
    remove_column :isometries, :dn2, :string
    remove_column :isometries, :dn3, :string
    remove_column :isometries, :test_pack_number, :integer

    # Add new string field
    add_column :isometries, :dn, :string

    # Change decimal fields to integer
    change_column :isometries, :rt, :integer
    change_column :isometries, :vt2, :integer
    change_column :isometries, :pt2, :integer
  end
end
