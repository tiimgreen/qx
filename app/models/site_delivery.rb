class SiteDelivery < ApplicationRecord
  include SectorModel
  include DocuvitaUploadable

  belongs_to :project
  belongs_to :user

  CHECK_SPOOLS_STATUSES = [ "N/A", "Passed", "Failed" ].freeze

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id ] }
  # validates :check_spools_status, inclusion: { in: CHECK_SPOOLS_STATUSES }, on: :update
  validates :check_spools_comment, length: { maximum: 2000 }

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

   joins("LEFT JOIN users ON site_deliveries.user_id = users.id")
    .where(
      "users.first_name LIKE :search OR
       users.email LIKE :search OR
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
