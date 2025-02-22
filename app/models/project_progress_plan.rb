class ProjectProgressPlan < ApplicationRecord
  belongs_to :project
  has_many :weekly_progress_entries, dependent: :destroy

  enum work_type: {
    isometry: 0,
    prefabrication: 1,
    site_assembly: 2
  }

  validates :start_date, :end_date, :work_type, presence: true
  validate :end_date_after_start_date
  validate :unique_work_type_per_project, on: :create

  before_create :set_initial_revision_values

  scope :latest_revisions, -> { where(revision_last: true) }

  def create_revision
    ProjectProgressPlanRevisionCreator.new(self).create_revision
  end

  private

  def set_initial_revision_values
    self.revision_number ||= 1
    self.revision_last = true
  end

  def unique_work_type_per_project
    return unless project && work_type

    if project.project_progress_plans.latest_revisions.where(work_type: work_type).exists?
      errors.add(:work_type, "already exists for this project")
    end
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
