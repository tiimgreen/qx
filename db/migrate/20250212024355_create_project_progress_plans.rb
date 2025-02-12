class CreateProjectProgressPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :project_progress_plans do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :work_type
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps
    end
  end
end
