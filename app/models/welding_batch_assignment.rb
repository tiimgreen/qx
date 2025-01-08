class WeldingBatchAssignment < ApplicationRecord
  belongs_to :work_preparation
  belongs_to :welding
  belongs_to :material_certificate, optional: true
  belongs_to :material_certificate1, class_name: 'MaterialCertificate', optional: true

  validates :welding_id, presence: true
end
