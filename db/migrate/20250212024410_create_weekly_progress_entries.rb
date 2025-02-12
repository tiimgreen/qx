class CreateWeeklyProgressEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :weekly_progress_entries do |t|
      t.references :project_progress_plan, null: false, foreign_key: true
      t.integer :week_number, null: false
      t.integer :year, null: false
      t.decimal :expected_value, precision: 10, scale: 2
      t.decimal :actual_value, precision: 10, scale: 2

      t.timestamps
    end

    add_index :weekly_progress_entries, [:project_progress_plan_id, :week_number, :year], unique: true, name: 'idx_weekly_progress_unique_week'
  end
end
