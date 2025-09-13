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

  # Allow blank ("") so the dropdown can be saved empty
  validates :result, inclusion: { in: RESULT_TYPES }, allow_blank: true
  validates :result1, inclusion: { in: RESULT_TYPES }, allow_blank: true

  private

  # Sets `material_certificate_id` / `_id1` based on the entered batch numbers so
  # that nested‐attributes forms that only fill the `batch_number*` fields still
  # establish the ActiveRecord associations. This enables later logic on the
  # isometry to easily pick up the referenced certificates.
  def assign_material_certificates_from_batch_numbers
    # First set handling
    if material_certificate_id.present?
      # If ID is explicitly provided (from autocomplete hidden field), respect it
      if batch_number.blank?
        # Optionally sync the batch number if it's blank
        self.batch_number = material_certificate&.batch_number
      end
    else
      if batch_number.present?
        matches = MaterialCertificate.where(batch_number: batch_number)
        # Only auto-assign when the batch number uniquely identifies a certificate
        self.material_certificate_id = matches.one? ? matches.first.id : nil
      else
        self.material_certificate_id = nil
      end
    end

    # Second set handling
    if material_certificate1_id.present?
      if batch_number1.blank?
        self.batch_number1 = material_certificate1&.batch_number
      end
    else
      if batch_number1.present?
        matches1 = MaterialCertificate.where(batch_number: batch_number1)
        self.material_certificate1_id = matches1.one? ? matches1.first.id : nil
      else
        self.material_certificate1_id = nil
      end
    end
  end
end
