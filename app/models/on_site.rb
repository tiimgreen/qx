class OnSite < ApplicationRecord
  include SectorModel
  include DocuvitaUploadable
  include LockedByArchivedProject

  belongs_to :project
  belongs_to :user

  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id ] }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES }
  validates :on_hold_comment, length: { maximum: 2000 }


  # has_many_attached :on_hold_images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end

  # has_many_attached :images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

    joins("LEFT JOIN users ON on_sites.user_id = users.id")
      .joins("LEFT JOIN isometries ON on_sites.isometry_id = isometries.id")
      .where(
        "users.first_name LIKE :search OR
        users.email LIKE :search OR
        isometries.line_id LIKE :search OR
        CAST(isometries.revision_number AS TEXT) LIKE :search OR
        on_sites.work_package_number LIKE :search OR
        on_sites.on_hold_status LIKE :search OR
        on_sites.on_hold_comment LIKE :search",
        search: term
      )
      .distinct
  }

  def on_hold?
    on_hold_status == "On Hold"
  end

  # # Helper methods for Docuvita document access
  def on_hold_images
    docuvita_documents.where(documentable_type: "OnSite", document_sub_type: "on_hold_image")
  end
  alias_method :on_hold_documents, :on_hold_images

  def on_site_images
    docuvita_documents.where(documentable_type: "OnSite", document_sub_type: "on_site_image")
  end
  alias_method :on_site_documents, :on_site_images
end
