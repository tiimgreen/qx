class Prefabrication < ApplicationRecord
  belongs_to :project
  belongs_to :work_location, optional: true
  belongs_to :user
  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze

  has_many_attached :on_hold_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end

  validates :work_package_number, presence: true
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES }
  validates :on_hold_comment, length: { maximum: 2000 }

  scope :active, -> { where(active: true) }

  def on_hold?
    on_hold_status == "On Hold"
  end

  # Validate image format and size
  validate :validate_image_format

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
