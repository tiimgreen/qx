class WeeklyProgressEntry < ApplicationRecord
  belongs_to :project_progress_plan

  validates :week_number, :year, presence: true
  validates :week_number, numericality: { greater_than: 0, less_than_or_equal_to: 53 }
  validates :year, numericality: { greater_than: 2000 }
  validates :expected_value, :actual_value, numericality: { allow_nil: true }

  validates :week_number, uniqueness: {
    scope: [ :project_progress_plan_id, :year ],
    message: "already has an entry for this week and year"
  }
end
