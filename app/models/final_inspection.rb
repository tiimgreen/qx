class FinalInspection < ApplicationRecord
  include SectorModel
  include DocuvitaUploadable
  include LockedByArchivedProject

  belongs_to :project
  belongs_to :work_location
  belongs_to :user
  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze
  VISUAL_STATUSES = [ "Passed", "Failed" ].freeze
  VT2_STATUSES = [ "Passed", "Failed", "N/A" ].freeze
  PT2_STATUSES = [ "Passed", "Failed", "N/A" ].freeze
  RT_STATUSES = [ "Passed", "Failed", "N/A" ].freeze

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id ] }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }
  validates :on_hold_comment, length: { maximum: 2000 }

  # remove after migrating
  # has_many_attached :on_hold_images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end

  # has_many_attached :visual_check_images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end

  # has_many_attached :vt2_check_images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end

  # has_many_attached :pt2_check_images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end

  # has_many_attached :rt_check_images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end


  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

    joins("LEFT JOIN work_locations ON final_inspections.work_location_id = work_locations.id")
    .joins("LEFT JOIN users ON final_inspections.user_id = users.id")
    .where(
      "work_locations.location_type LIKE :search OR
       work_locations.name LIKE :search OR
       work_locations.key LIKE :search OR
       users.first_name LIKE :search OR
       users.email LIKE :search OR
       final_inspections.work_package_number LIKE :search OR
       final_inspections.on_hold_status LIKE :search OR
       final_inspections.on_hold_comment LIKE :search OR
       final_inspections.visual_check_status LIKE :search OR
       final_inspections.visual_check_comment LIKE :search OR
       final_inspections.vt2_check_status LIKE :search OR
       final_inspections.vt2_check_comment LIKE :search OR
       final_inspections.pt2_check_status LIKE :search OR
       final_inspections.pt2_check_comment LIKE :search OR
       final_inspections.rt_check_status LIKE :search OR
       final_inspections.rt_check_comment LIKE :search",
      search: term
    )
    .distinct
  }

  def on_hold?
    on_hold_status == "On Hold"
  end

  # # Helper methods for Docuvita document access
  def on_hold_images
    docuvita_documents.where(documentable_type: "FinalInspection", document_sub_type: "on_hold_image")
  end

  def visual_check_images
    docuvita_documents.where(documentable_type: "FinalInspection", document_sub_type: "visual_check_image")
  end

  def vt2_check_images
    docuvita_documents.where(documentable_type: "FinalInspection", document_sub_type: "vt2_check_image")
  end

  def pt2_check_images
    docuvita_documents.where(documentable_type: "FinalInspection", document_sub_type: "pt2_check_image")
  end

  def rt_check_images
    docuvita_documents.where(documentable_type: "FinalInspection", document_sub_type: "rt_check_image")
  end
end
