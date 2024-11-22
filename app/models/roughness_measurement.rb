class RoughnessMeasurement < ApplicationRecord
  belongs_to :delivery_item
  has_many_attached :measurement_reports

  validates :measurement_date, presence: true
  validates :measured_value, presence: true, numericality: true

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    joins(delivery_item: { incoming_delivery: :project })
      .where(
        "projects.name LIKE :search OR
        projects.project_number LIKE :search OR
        delivery_items.tag_number LIKE :search OR
        delivery_items.batch_number LIKE :search",
        search: term
      ).distinct
  }
end
