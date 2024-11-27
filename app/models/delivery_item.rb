class DeliveryItem < ApplicationRecord
  include Holdable

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

  validates :on_hold_date, presence: true, if: :on_hold?
  validates :on_hold_reason, presence: true, if: :on_hold?

  validates :delivery_note_position, presence: true
  validates :tag_number, presence: true, uniqueness: { scope: :incoming_delivery_id }
  validates :batch_number, presence: true
  validates :actual_quantity, presence: true, numericality: { greater_than: 0 }
  validates :target_quantity, presence: true, numericality: { greater_than: 0 }

  CHECK_STATUSES = [ "N/A", "Passed", "Failed" ].freeze
  VISUAL_STATUSES = [ "Passed", "Failed" ].freeze

  validates :quantity_check_status, inclusion: { in: CHECK_STATUSES, allow_nil: true }
  validates :dimension_check_status, inclusion: { in: CHECK_STATUSES, allow_nil: true }
  validates :visual_check_status, inclusion: { in: VISUAL_STATUSES, allow_nil: true }
  validates :vt2_check_status, inclusion: { in: CHECK_STATUSES, allow_nil: true }
  validates :ra_check_status, inclusion: { in: CHECK_STATUSES, allow_nil: true }

  serialize :specifications, coder: JSON

  before_save :ensure_hold_consistency


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

  private

  def ensure_hold_consistency
    if on_hold?
      self.on_hold_date ||= Time.current
    else
      self.on_hold_date = nil
      self.on_hold_reason = nil
    end
  end
end
