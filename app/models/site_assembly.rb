class SiteAssembly < ApplicationRecord
  include SectorModel
  include DocuvitaUploadable

  belongs_to :project
  belongs_to :user
  belongs_to :isometry, optional: true

  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id ] }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES }
  validates :on_hold_comment, length: { maximum: 2000 }

  has_many_attached :on_hold_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

    joins("LEFT JOIN users ON site_assemblies.user_id = users.id")
      .where(
        "users.first_name LIKE :search OR
         users.email LIKE :search OR
         site_assemblies.work_package_number LIKE :search OR
         site_assemblies.on_hold_status LIKE :search OR
         site_assemblies.on_hold_comment LIKE :search",
        search: term
      )
      .distinct
  }

  def on_hold?
    on_hold_status == "On Hold"
  end

  # Helper methods for Docuvita document access
  # def on_hold_images
  #   docuvita_documents.where(documentable_type: "SiteAssembly", document_sub_type: "on_hold_image")
  # end
  # alias_method :on_hold_documents, :on_hold_images
end
