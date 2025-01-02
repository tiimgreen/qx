class Prefabrication < ApplicationRecord
  belongs_to :work_location
  belongs_to :user
  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze

  validates :work_package_number, presence: true
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES }
  validates :on_hold_comment, length: { maximum: 2000 }
  has_many_attached :on_hold_images

  scope :active, -> { where(active: true) }
end
