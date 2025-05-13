class DeliveryItem < ApplicationRecord
  belongs_to :incoming_delivery
  belongs_to :user, optional: true
  include DocuvitaUploadable

  has_one :project, through: :incoming_delivery

  # Remove ActiveStorage attachments
  # has_many_attached :quantity_check_images
  # has_many_attached :dimension_check_images
  # has_many_attached :visual_check_images
  # has_many_attached :vt2_check_images
  # has_many_attached :ra_check_images
  # has_many_attached :on_hold_images

  # before_destroy :purge_attached_files

  validates :delivery_note_position, presence: true, on: :create
  validates :tag_number, presence: true, uniqueness: { scope: :incoming_delivery_id }, on: :create
  validates :batch_number, presence: true, on: :create
  validates :actual_quantity, presence: true, numericality: { greater_than: 0 }, on: :create
  validates :target_quantity, presence: true, numericality: { greater_than: 0 }, on: :create

  CHECK_STATUSES = [ "N/A", "Passed", "Failed" ].freeze
  VISUAL_STATUSES = [ "Passed", "Failed" ].freeze
  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze

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

  ALLOWED_SORT_COLUMNS = %w[
    delivery_note_position tag_number batch_number
    item_description completed on_hold_status
    quantity_check_status dimension_check_status visual_check_status
    vt2_check_status ra_check_status
  ].freeze

  scope :sorted_by, ->(sort_column, direction) {
    if sort_column.present? && ALLOWED_SORT_COLUMNS.include?(sort_column.to_s)
      reorder(sort_column => validated_direction(direction))
    else
      order(created_at: :asc)
    end
  }

  def self.validated_direction(direction)
    %w[asc desc].include?(direction.to_s) ? direction : "asc"
  end

  def on_hold?
    on_hold_status == "On Hold"
  end

  def update_completion_status
    update(completed: all_checks_passed?)
  end

  # Helper methods for Docuvita document access
  def quantity_check_images
    docuvita_documents.where(documentable_type: "DeliveryItem", document_sub_type: "quantity_check_image")
  end

  def dimension_check_images
    docuvita_documents.where(documentable_type: "DeliveryItem", document_sub_type: "dimension_check_image")
  end

  def visual_check_images
    docuvita_documents.where(documentable_type: "DeliveryItem", document_sub_type: "visual_check_image")
  end

  def vt2_check_images
    docuvita_documents.where(documentable_type: "DeliveryItem", document_sub_type: "vt2_check_image")
  end

  def ra_check_images
    docuvita_documents.where(documentable_type: "DeliveryItem", document_sub_type: "ra_check_image")
  end

  def on_hold_images
    docuvita_documents.where(documentable_type: "DeliveryItem", document_sub_type: "on_hold_image")
  end

  private

  def purge_attached_files
    # No need to purge ActiveStorage files anymore
    # quantity_check_images.purge
    # dimension_check_images.purge
    # visual_check_images.purge
    # vt2_check_images.purge
    # ra_check_images.purge
    # on_hold_images.purge
  end

  def all_checks_passed?
    return false if on_hold?

    check_statuses = [
      quantity_check_status,
      dimension_check_status,
      visual_check_status,
      vt2_check_status,
      ra_check_status
    ].compact

    # Return false if any status is Failed
    return false if check_statuses.any? { |status| status == "Failed" }

    # All remaining statuses must be either Passed or N/A
    check_statuses.all? { |status| [ "Passed", "N/A" ].include?(status) }
  end
end
