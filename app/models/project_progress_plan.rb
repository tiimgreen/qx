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

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
