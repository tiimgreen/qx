class MaterialCertificate < ApplicationRecord
  has_one_attached :certificate_file
  has_many :isometry_material_certificates, dependent: :destroy
  has_many :isometries, through: :isometry_material_certificates
  has_many :weldings_as_certificate, class_name: "Welding", foreign_key: "material_certificate_id", dependent: :nullify
  has_many :weldings_as_certificate1, class_name: "Welding", foreign_key: "material_certificate1_id", dependent: :nullify
  has_many :docuvita_documents, as: :documentable, dependent: :destroy # Add this line

  validates :certificate_number,
            presence: true,
            uniqueness: { case_sensitive: false, message: "already exists (case insensitive)" }
  validates :batch_number, presence: true
  validates :issue_date, presence: true

  before_validation :upcase_certificate_number

  scope :pending, -> { where(status: "pending") }

  scope :search_by_term, ->(term) {
    where("LOWER(certificate_number) LIKE :term OR LOWER(batch_number) LIKE :term OR LOWER(issuer_name) LIKE :term OR LOWER(line_id) LIKE :term",
          term: "%#{term&.downcase}%")
  }

  private

  def upcase_certificate_number
    self.certificate_number = certificate_number.upcase if certificate_number.present?
  end
end
