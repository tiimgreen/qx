class MaterialCertificate < ApplicationRecord
  has_one_attached :certificate_file

  validates :certificate_number,
            presence: true,
            uniqueness: { case_sensitive: false, message: "already exists (case insensitive)" }
  validates :batch_number, presence: true
  validates :issue_date, presence: true

  before_validation :upcase_certificate_number

  scope :pending, -> { where(status: "pending") }
  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    left_joins(:delivery_items)
      .left_joins(delivery_items: :incoming_delivery)
      .where(
        "material_certificates.certificate_number LIKE ? OR " \
        "material_certificates.batch_number LIKE ? OR " \
        "material_certificates.issuer_name LIKE ? OR " \
        "delivery_items.tag_number LIKE ? OR " \
        "delivery_items.batch_number LIKE ? OR " \
        "delivery_items.item_description LIKE ?",
        term, term, term, term, term, term
      ).distinct
  }

  private

  def upcase_certificate_number
    self.certificate_number = certificate_number.upcase if certificate_number.present?
  end
end
