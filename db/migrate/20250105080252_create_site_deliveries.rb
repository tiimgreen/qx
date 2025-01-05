class CreateSiteDeliveries < ActiveRecord::Migration[7.2]
  def change
    create_table :site_deliveries do |t|
      t.integer :project_id
      t.string :work_package_number
      t.datetime :completed
      t.text :on_hold_status
      t.text :on_hold_comment
      t.datetime :on_hold_date
      t.integer :user_id
      t.decimal :total_time, precision: 10, scale: 2

      t.timestamps
    end
  end
end
