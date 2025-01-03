class FinalInspection < ApplicationRecord
  belongs_to :project
  belongs_to :work_location
  belongs_to :user
  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze
  VISUAL_STATUSES = [ "Passed", "Failed" ].freeze

  has_many_attached :on_hold_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end

  has_many_attached :visual_check_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end

  has_many_attached :vt2_check_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end

  validates :visual_check_status, inclusion: { in: VISUAL_STATUSES, allow_nil: true }
  validates :work_package_number, presence: true, uniqueness: { scope: :project_id }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }
  validates :on_hold_comment, length: { maximum: 2000 }
  validates :total_time, numericality: { precision: 10, scale: 2 }

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
       final_inspections.on_hold_comment LIKE :search",
      search: term
    )
    .distinct
  }

  def on_hold?
    on_hold_status == "On Hold"
  end

  # Validate image format and size
  validate :validate_image_format

  private

  def validate_image_format
    validate_images(on_hold_images)
    validate_images(visual_check_images)
    validate_images(vt2_check_images)
  end

  def validate_images(images)
    return unless images.attached?

    images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/png])
        errors.add(:base, "Invalid format for #{image.filename}")
        image.purge
      end

      if image.byte_size > 5.megabytes
        errors.add(:base, "#{image.filename} is too large")
        image.purge
      end
    end
  end
end
