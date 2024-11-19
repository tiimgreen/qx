class InspectionDefect < ApplicationRecord
  SEVERITY_LEVELS = %w[critical major minor].freeze

  belongs_to :quality_inspection

  validates :description, presence: true
  validates :severity, presence: true, inclusion: { in: SEVERITY_LEVELS }
  validates :corrective_action, length: { minimum: 10 }, allow_blank: true

  scope :critical, -> { where(severity: "critical") }
  scope :major, -> { where(severity: "major") }
  scope :minor, -> { where(severity: "minor") }
end
