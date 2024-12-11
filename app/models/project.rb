class Project < ApplicationRecord
  has_many :incoming_deliveries, dependent: :destroy
  has_many :delivery_items, through: :incoming_deliveries
  has_many :isometries, dependent: :destroy
  has_many :isometry_material_certificates, through: :isometries
  has_many :material_certificates, through: :isometry_material_certificates

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
