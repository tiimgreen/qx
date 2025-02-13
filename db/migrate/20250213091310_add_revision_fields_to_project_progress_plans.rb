class AddRevisionFieldsToProjectProgressPlans < ActiveRecord::Migration[7.2]
  def change
    add_column :project_progress_plans, :revision_number, :integer
    add_index :project_progress_plans, :revision_number
    add_column :project_progress_plans, :revision_last, :boolean
    add_index :project_progress_plans, :revision_last
  end
end
