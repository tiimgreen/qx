class UpdateWeldingsTableFields < ActiveRecord::Migration[7.2]
  def change
    # Remove datetime fields
    remove_column :weldings, :rt_date
    remove_column :weldings, :pt_date
    remove_column :weldings, :vt_date

    # Remove done_by fields
    remove_column :weldings, :rt_done_by1
    remove_column :weldings, :pt_done_by1
    remove_column :weldings, :vt_done_by1

    # Change welder1 from string to datetime
    change_column :weldings, :welder1, :datetime

    # Add new boolean fields
    add_column :weldings, :is_orbital, :boolean
    add_column :weldings, :is_manuell, :boolean
  end
end
