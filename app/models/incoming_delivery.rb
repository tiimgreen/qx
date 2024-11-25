class IncomingDelivery < ApplicationRecord
  belongs_to :project
  belongs_to :work_location
  has_many_attached :delivery_notes
  has_many :delivery_items, dependent: :destroy
  has_many :missing_delivery_items, dependent: :destroy
  has_many :material_certificates, through: :delivery_items

  validates :delivery_date, presence: true
  validates :order_number, presence: true, uniqueness: true
  validates :supplier_name, presence: true
  validates :delivery_note_number, presence: true

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    left_joins(:project)
      .where(
        "incoming_deliveries.order_number LIKE :search OR
        incoming_deliveries.supplier_name LIKE :search OR
        projects.name LIKE :search OR
        projects.project_number LIKE :search",
        search: term
      ).distinct
  }
end
