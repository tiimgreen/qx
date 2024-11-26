class Project < ApplicationRecord
  has_many :incoming_deliveries
  has_many :material_certificates
  has_many :delivery_items, through: :incoming_deliveries

  belongs_to :user, optional: true

  validates :project_number, presence: true, uniqueness: true
  validates :name, presence: true

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    where(
      "projects.project_number LIKE :search OR
       projects.name LIKE :search OR
       projects.description LIKE :search OR
       projects.project_manager LIKE :search OR
       projects.client_name LIKE :search",
      search: term
    )
  }
end
