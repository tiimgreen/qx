class TestPack < ApplicationRecord
  include SectorModel
  include DocuvitaUploadable
  include LockedByArchivedProject

  belongs_to :project
  belongs_to :work_location
  belongs_to :user

  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze
  TEST_PACK_TYPES = [ "pressure_test", "leak_test" ].freeze

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id, :test_pack_type ] }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }
  validates :on_hold_comment, length: { maximum: 2000 }
  validates :test_pack_type, presence: true

  # has_many_attached :on_hold_images do |attachable|
  #   attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  #   attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  # end

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

    joins("LEFT JOIN work_locations ON test_packs.work_location_id = work_locations.id")
    .joins("LEFT JOIN users ON test_packs.user_id = users.id")
    .joins("LEFT JOIN isometries ON test_packs.isometry_id = isometries.id")
    .where(
      "work_locations.location_type LIKE :search OR
       (LOWER(:search) LIKE '%werkstatt%' AND work_locations.location_type = 'workshop') OR
       (LOWER(:search) LIKE '%vorfertigung%' AND work_locations.location_type = 'prefabrication') OR
       (LOWER(:search) LIKE '%baustelle%' AND work_locations.location_type = 'construction_site') OR
       work_locations.name LIKE :search OR
       work_locations.key LIKE :search OR
       users.first_name LIKE :search OR
       users.email LIKE :search OR
       isometries.line_id LIKE :search OR
       CAST(isometries.revision_number AS TEXT) LIKE :search OR
       REPLACE(LOWER(test_packs.test_pack_type), '_', ' ') LIKE LOWER(:search) OR
       test_packs.work_package_number LIKE :search OR
       test_packs.dp_team LIKE :search OR
       test_packs.operating_pressure LIKE :search OR
       test_packs.dp_pressure LIKE :search OR
       test_packs.dip_team LIKE :search OR
       test_packs.dip_pressure LIKE :search OR
       test_packs.on_hold_status LIKE :search OR
       test_packs.on_hold_comment LIKE :search",
      search: term
    )
    .distinct # Add this to avoid duplicate results
  }

  def on_hold?
    on_hold_status == "On Hold"
  end

  def one_test?
    one_test
  end

  def completed?
    completed.present?
  end

  def self.completed_for?(isometry)
    return true if isometry.test_packs.any? { |tp| tp.one_test? && tp.completed? }
    completed_count = isometry.test_packs.count { |tp| tp.completed.present? }
    completed_count == TEST_PACK_TYPES.size
  end

  def self.in_progress_for?(isometry)
    isometry.test_packs.any? { |tp| tp.completed.nil? }
  end

  def self.status_for(isometry)
    test_packs = isometry.test_packs
    return :not_started if test_packs.empty?

    if test_packs.any? { |tp| tp.one_test? && tp.completed? }
      :completed
    elsif completed_count = test_packs.count { |tp| tp.completed.present? }
      if completed_count == TEST_PACK_TYPES.size
        :completed
      else
        :in_progress
      end
    elsif test_packs.any?
      :in_progress
    else
      :not_started
    end
  end

  def self.status_details_for(isometry)
    TEST_PACK_TYPES.each_with_object({}) do |type, hash|
      tp = isometry.test_packs.find_by(test_pack_type: type)
      hash[type] = if tp&.completed.present?
                    :completed
      elsif tp
                    :in_progress
      else
                    :not_started
      end
    end
  end

  # # Helper methods for Docuvita document access
  def on_hold_images
    docuvita_documents.where(documentable_type: "TestPack", document_sub_type: "on_hold_image")
  end
  alias_method :on_hold_documents, :on_hold_images
end
