class SiteDelivery < ApplicationRecord
  belongs_to :project
  belongs_to :user

  CHECK_SPOOLS_STATUSES = [ "N/A", "Passed", "Failed" ].freeze

  has_many_attached :check_spools_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end

  validates :work_package_number, presence: true, uniqueness: { scope: :project_id }
  validates :check_spools_status, inclusion: { in: CHECK_SPOOLS_STATUSES }
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

  # Validate image format and size
  validate :validate_image_format

  private

  def validate_image_format
    return unless check_spools_images.attached?

    check_spools_images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/png])
        errors.add(:check_spools_images, :invalid_format)
        image.purge
      end

      if image.byte_size > 5.megabytes
        errors.add(:check_spool_images, :too_large)
        image.purge
      end
    end
  end
end
