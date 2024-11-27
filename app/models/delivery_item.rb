class DeliveryItem < ApplicationRecord
  belongs_to :incoming_delivery
  belongs_to :user, optional: true


  has_many :material_certificate_items, dependent: :destroy
  has_many :material_certificates, through: :material_certificate_items

  has_one :project, through: :incoming_delivery

  has_many_attached :quantity_check_images
  has_many_attached :dimension_check_images
  has_many_attached :visual_check_images
  has_many_attached :vt2_check_images
  has_many_attached :ra_check_images
  has_many_attached :on_hold_images

  validates :delivery_note_position, presence: true
  validates :tag_number, presence: true, uniqueness: { scope: :incoming_delivery_id }
  validates :batch_number, presence: true
  validates :actual_quantity, presence: true, numericality: { greater_than: 0 }
  validates :target_quantity, presence: true, numericality: { greater_than: 0 }

  CHECK_STATUSES = [ "N/A", "Passed", "Failed" ].freeze
  VISUAL_STATUSES = [ "Passed", "Failed" ].freeze
  ON_HOLD_STATUSES = [ "N/A", "Yes" ].freeze

  validates :quantity_check_status, inclusion: { in: CHECK_STATUSES, allow_nil: true }
  validates :dimension_check_status, inclusion: { in: CHECK_STATUSES, allow_nil: true }
  validates :visual_check_status, inclusion: { in: VISUAL_STATUSES, allow_nil: true }
  validates :vt2_check_status, inclusion: { in: CHECK_STATUSES, allow_nil: true }
  validates :ra_check_status, inclusion: { in: CHECK_STATUSES, allow_nil: true }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }
  serialize :specifications, coder: JSON


  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    where(
      "delivery_items.item_number LIKE :search OR
       delivery_items.description LIKE :search OR
       delivery_items.unit LIKE :search",
      search: term
    )
  }

  def on_hold?
    on_hold_status == 'Yes'
  end
end
