class MaterialCertificate < ApplicationRecord
  belongs_to :project
  has_one_attached :certificate_file
  has_many :material_certificate_items, dependent: :destroy
  has_many :delivery_items, through: :material_certificate_items

  validates :certificate_number,
            presence: true,
            uniqueness: { case_sensitive: false, message: "already exists (case insensitive)" }
  validates :batch_number, presence: true
  validates :issue_date, presence: true

  scope :pending, -> { where(status: "pending") }
  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    left_joins(:project)
      .left_joins(material_certificate_items: :delivery_item)
      .left_joins(material_certificate_items: { delivery_item: :incoming_delivery })
      .where(
        "material_certificates.certificate_number LIKE :search OR
        material_certificates.batch_number LIKE :search OR
        delivery_items.tag_number LIKE :search OR
        delivery_items.batch_number LIKE :search OR
        incoming_deliveries.order_number LIKE :search OR
        projects.name LIKE :search OR
        projects.project_number LIKE :search",
        search: term
      ).distinct
    }
end
