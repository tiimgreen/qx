class SiteDelivery < ApplicationRecord
  include SectorModel
  include DocuvitaUploadable
  include LockedByArchivedProject

  belongs_to :project
  belongs_to :user

  CHECK_SPOOLS_STATUSES = [ "N/A", "Passed", "Failed" ].freeze

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id ] }
  # validates :check_spools_status, inclusion: { in: CHECK_SPOOLS_STATUSES }, on: :update
  validates :check_spools_comment, length: { maximum: 2000 }


  # has_many_attached :check_spools_images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

   joins("LEFT JOIN users ON site_deliveries.user_id = users.id")
   .joins("LEFT JOIN isometries ON site_deliveries.isometry_id = isometries.id")
    .where(
      "users.first_name LIKE :search OR
       users.email LIKE :search OR
       isometries.line_id LIKE :search OR
       CAST(isometries.revision_number AS TEXT) LIKE :search OR
       site_deliveries.work_package_number LIKE :search OR
       site_deliveries.check_spools_status LIKE :search OR
       site_deliveries.check_spools_comment LIKE :search",
      search: term
    )
    .distinct
  }

  def passed?
    check_spools_status == "Passed"
  end

  def failed?
    check_spools_status == "Failed"
  end

  def check_spools_images
    docuvita_documents.where(documentable_type: "SiteDelivery", document_sub_type: "check_spools_image")
  end
end
