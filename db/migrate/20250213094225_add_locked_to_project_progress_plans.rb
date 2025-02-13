class AddLockedToProjectProgressPlans < ActiveRecord::Migration[7.2]
  def change
    add_column :project_progress_plans, :locked, :boolean, default: false
    add_index :project_progress_plans, :locked
  end
end
