class Welding < ApplicationRecord
  # Relationships
  belongs_to :material_certificate, optional: true

  # Validations
  validates :number, presence: true
  validates :component, presence: true
  validates :batch_number, presence: true

  # Fields from the table:
  # number (Naht Nr.) - string
  # component (Komponente) - string
  # dimension (Abmessung) - string
  # material (Werkstoff) - string
  # batch_number (Charge) - string
  # type_code (Typ) - string
  # wps - string
  # process (Prozess) - string
  # welder (Schweisser) - string
  # rt_date (RT Datum) - datetime
  # pt_date (PT Datum) - datetime
  # vt_date (VT Datum) - datetime
  # result (Erg.) - string
end
