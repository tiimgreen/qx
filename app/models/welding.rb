class Welding < ApplicationRecord
  # Relationships
  belongs_to :isometry, optional: true
  belongs_to :material_certificate, optional: true
  belongs_to :material_certificate1, class_name: "MaterialCertificate", optional: true

  # Validations
  validates :number, presence: true
  validates :component, presence: true

  # Automatically resolve certificates from entered batch numbers
  before_validation :assign_material_certificates_from_batch_numbers

  # Define allowed values for process fields
  RESULT_TYPES = [ "ne", "e" ].freeze

  validates :result, inclusion: { in: RESULT_TYPES }, allow_nil: true
  validates :result1, inclusion: { in: RESULT_TYPES }, allow_nil: true

  private

  # Sets `material_certificate_id` / `_id1` based on the entered batch numbers so
  # that nested‐attributes forms that only fill the `batch_number*` fields still
  # establish the ActiveRecord associations. This enables later logic on the
  # isometry to easily pick up the referenced certificates.
  def assign_material_certificates_from_batch_numbers
    # Handle first batch number and certificate
    if batch_number.present?
      found_cert = MaterialCertificate.find_by(batch_number: batch_number)
      self.material_certificate_id = found_cert&.id
    else
      # Clear certificate when batch number is removed
      self.material_certificate_id = nil
    end

    # Handle second batch number and certificate
    if batch_number1.present?
      found_cert1 = MaterialCertificate.find_by(batch_number: batch_number1)
      self.material_certificate1_id = found_cert1&.id
    else
      # Clear certificate when batch number is removed
      self.material_certificate1_id = nil
    end
  end
end
