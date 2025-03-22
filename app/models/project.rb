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
  has_many :project_sectors, dependent: :destroy

  # Virtual attribute for sector_ids
  attr_accessor :sector_ids

  belongs_to :user, optional: true

  has_many :project_users, dependent: :destroy
  has_many :users, through: :project_users
  has_many :project_progress_plans, dependent: :destroy

  validates :project_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :project_manager_client, presence: true
  validates :project_manager_qualinox, presence: true
  validates :project_end, presence: true

  # Filter validations
  validates :sollist_filter1, presence: true
  validates :sollist_filter2, :sollist_filter3, :progress_filter1, :progress_filter2,
            presence: true, if: :requires_filters?

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

  private

  def requires_filters?
    # Only require filters if the project exists (not a new record)
    # or if any of the filters are already set
    persisted? || [ sollist_filter2, sollist_filter3, progress_filter1, progress_filter2 ].any?(&:present?)
  end
end
