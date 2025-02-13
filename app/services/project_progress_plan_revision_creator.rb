class ProjectProgressPlanRevisionCreator
  def initialize(project_progress_plan)
    @project_progress_plan = project_progress_plan
  end

  def create_revision
    ActiveRecord::Base.transaction do
      # Mark old revisions as not latest
      ProjectProgressPlan.where(
        project_id: @project_progress_plan.project_id,
        work_type: @project_progress_plan.work_type
      ).update_all(revision_last: false)

      # Create new revision
      new_plan = @project_progress_plan.dup
      new_plan.revision_number = @project_progress_plan.revision_number + 1
      new_plan.revision_last = true

      # Copy associated weekly progress entries
      @project_progress_plan.weekly_progress_entries.each do |entry|
        new_entry = entry.dup
        new_plan.weekly_progress_entries << new_entry
      end

      new_plan.save!
      new_plan
    end
  end
end
