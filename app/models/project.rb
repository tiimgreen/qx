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
  has_many :sectors, through: :project_sectors

  belongs_to :sollist_filter1_sector, class_name: "Sector"
  belongs_to :sollist_filter2_sector, class_name: "Sector", optional: true
  belongs_to :sollist_filter3_sector, class_name: "Sector", optional: true
  belongs_to :progress_filter1_sector, class_name: "Sector", optional: true
  belongs_to :progress_filter2_sector, class_name: "Sector", optional: true

  belongs_to :user, optional: true

  has_many :project_users, dependent: :destroy
  has_many :users, through: :project_users
  has_many :project_progress_plans, dependent: :destroy

  validates :project_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :project_manager_client, presence: true
  validates :project_manager_qualinox, presence: true
  validates :project_end, presence: true
  validates :client_name, presence: true

  # Filter validations
  validates :sollist_filter1_sector, presence: true
  validates :sollist_filter2_sector, :sollist_filter3_sector,
            presence: true, if: :requires_filters?
  validates :progress_filter1_sector, :progress_filter2_sector,
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

  # Returns true if all incoming deliveries are closed, false otherwise
  def all_incoming_deliveries_closed?
    return true if incoming_deliveries.none?
    incoming_deliveries.all?(&:closed?)
  end

  # app/models/project.rb
  scope :active,   -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  private

  def requires_filters?
    # Only require filters if the project exists (not a new record)
    # or if any of the filters are already set
    persisted? || [ sollist_filter2_sector, sollist_filter3_sector, progress_filter1_sector, progress_filter2_sector ].any?(&:present?)
  end
end
