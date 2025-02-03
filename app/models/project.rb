class Project < ApplicationRecord
  has_many :incoming_deliveries, dependent: :destroy
  has_many :delivery_items, through: :incoming_deliveries
  has_many :isometries, dependent: :destroy
  has_many :isometry_material_certificates, through: :isometries
  has_many :material_certificates, through: :isometry_material_certificates
  has_many :prefabrications, dependent: :destroy
  has_many :transports, dependent: :destroy
  has_many :final_inspections, dependent: :destroy
  has_many :work_preparations, dependent: :destroy
  has_many :site_deliveries, dependent: :destroy
  has_many :site_assemblies, dependent: :destroy
  has_many :on_sites, dependent: :destroy
  has_many :test_packs, dependent: :destroy
  has_many :pre_weldings, dependent: :destroy

  belongs_to :user, optional: true

  has_many :project_users
  has_many :users, through: :project_users

  validates :project_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :project_manager_client, presence: true
  validates :project_manager_qualinox, presence: true
  validates :project_end, presence: true

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    where(
      "projects.project_number LIKE :search OR
       projects.name LIKE :search OR
       projects.description LIKE :search OR
       projects.project_manager_client LIKE :search OR
       projects.project_manager_qualinox LIKE :search OR
       projects.client_name LIKE :search",
      search: term
    )
  }
end
