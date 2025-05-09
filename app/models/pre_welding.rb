class PreWelding < ApplicationRecord
  include SectorModel
  include DocuvitaUploadable

  belongs_to :project
  belongs_to :work_location, optional: true
  belongs_to :user
  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id ] }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES }
  validates :on_hold_comment, length: { maximum: 2000 }

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

    joins("LEFT JOIN work_locations ON pre_weldings.work_location_id = work_locations.id")
    .joins("LEFT JOIN users ON pre_weldings.user_id = users.id")
    .where(
      "work_locations.location_type LIKE :search OR
       work_locations.name LIKE :search OR
       work_locations.key LIKE :search OR
       users.first_name LIKE :search OR
       users.email LIKE :search OR
       pre_weldings.work_package_number LIKE :search OR
       pre_weldings.on_hold_status LIKE :search OR
       pre_weldings.on_hold_comment LIKE :search",
      search: term
    )
    .distinct # Add this to avoid duplicate results
  }

  # Helper methods for Docuvita document access
  def on_hold_images
    docuvita_documents.where(document_type: "on_hold_image")
  end
  alias_method :on_hold_documents, :on_hold_images

  def on_hold?
    on_hold_status == "On Hold"
  end
end
