class TestPack < ApplicationRecord
  include SectorModel

  belongs_to :project
  belongs_to :work_location
  belongs_to :user

  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze
  TEST_PACK_TYPES = [ "pressure_test", "leak_test" ].freeze

  has_many_attached :on_hold_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id, :test_pack_type ] }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }
  validates :on_hold_comment, length: { maximum: 2000 }
  validates :test_pack_type, presence: true

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

    joins("LEFT JOIN work_locations ON test_packs.work_location_id = work_locations.id")
    .joins("LEFT JOIN users ON test_packs.user_id = users.id")
    .where(
      "work_locations.location_type LIKE :search OR
       work_locations.name LIKE :search OR
       work_locations.key LIKE :search OR
       users.first_name LIKE :search OR
       users.email LIKE :search OR
       test_packs.work_package_number LIKE :search OR
       test_packs.test_pack_type LIKE :search OR
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

  # Validate image format and size
  validate :validate_image_format



  def self.completed_for?(isometry)
    completed_count = isometry.test_packs.count { |tp| tp.completed.present? }
    completed_count == TEST_PACK_TYPES.size
  end

  def self.in_progress_for?(isometry)
    isometry.test_packs.any? { |tp| tp.completed.nil? }
  end


  def self.status_for(isometry)
    test_packs = isometry.test_packs
    return :not_started if test_packs.empty?

    completed_count = test_packs.count { |tp| tp.completed.present? }

    if completed_count == TEST_PACK_TYPES.size
      :completed
    elsif completed_count > 0 || test_packs.any?
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

  private

  def validate_image_format
    return unless on_hold_images.attached?

    on_hold_images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/png])
        errors.add(:on_hold_images, :invalid_format)
        image.purge
      end

      if image.byte_size > 5.megabytes
        errors.add(:on_hold_images, :too_large)
        image.purge
      end
    end
  end
end
