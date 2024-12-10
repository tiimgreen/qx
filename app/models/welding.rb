class Welding < ApplicationRecord
  # Relationships
  belongs_to :isometry, optional: true
  belongs_to :material_certificate, optional: true
  belongs_to :material_certificate1, class_name: "MaterialCertificate", optional: true

  # Validations
  validates :number, presence: true
  validates :component, presence: true
  validates :batch_number, presence: true

  # Define allowed values for process fields
  PROCESS_TYPES = [ "Manuel", "Orbital" ].freeze
  RESULT_TYPES = [ "ne", "e" ].freeze

  validates :process, inclusion: { in: PROCESS_TYPES }, allow_nil: true
  validates :process1, inclusion: { in: PROCESS_TYPES }, allow_nil: true
  validates :result, inclusion: { in: RESULT_TYPES }, allow_nil: true
  validates :result1, inclusion: { in: RESULT_TYPES }, allow_nil: true
end
