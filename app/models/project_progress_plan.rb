class ProjectProgressPlan < ApplicationRecord
  include LockedByArchivedProject

  belongs_to :project
  belongs_to :work_type_sector, class_name: "Sector"
  has_many :weekly_progress_entries, dependent: :destroy

  validates :start_date, :end_date, :work_type_sector, presence: true
  validate :end_date_after_start_date
  validate :unique_work_type_per_project, on: :create
  validate :work_type_sector_is_valid_filter

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
    return unless project && work_type_sector

    if project.project_progress_plans
           .latest_revisions
           .where.not(id: id)
           .exists?(work_type_sector: work_type_sector)
      errors.add(:work_type_sector, :taken)
    end
  end

  def work_type_sector_is_valid_filter
    return unless project && work_type_sector

    valid_sectors = [
      project.sollist_filter1_sector_id,
      project.sollist_filter2_sector_id,
      project.sollist_filter3_sector_id
    ].compact

    unless valid_sectors.include?(work_type_sector.id)
      errors.add(:work_type_sector, :invalid)
    end
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, :after_start_date)
    end
  end
end
