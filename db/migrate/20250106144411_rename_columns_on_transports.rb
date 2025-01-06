class RenameColumnsOnTransports < ActiveRecord::Migration[7.2]
  def up
    # For transports table
    rename_column :transports, :on_hold_status, :check_spools_status
    rename_column :transports, :on_hold_comment, :check_spools_comment
    remove_column :transports, :on_hold_date

    # For site_deliveries table
    rename_column :site_deliveries, :on_hold_status, :check_spools_status
    rename_column :site_deliveries, :on_hold_comment, :check_spools_comment
    remove_column :site_deliveries, :on_hold_date
  end

  def down
    # For transports table
    rename_column :transports, :check_spools_status, :on_hold_status
    rename_column :transports, :check_spools_comment, :on_hold_comment
    add_column :transports, :on_hold_date, :datetime

    # For site_deliveries table
    rename_column :site_deliveries, :check_spools_status, :on_hold_status
    rename_column :site_deliveries, :check_spools_comment, :on_hold_comment
    add_column :site_deliveries, :on_hold_date, :datetime
  end
end
