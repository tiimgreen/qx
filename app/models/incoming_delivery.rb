class IncomingDelivery < ApplicationRecord
  include DocuvitaUploadable
  belongs_to :project
  belongs_to :work_location
  belongs_to :user, optional: true
  has_many_attached :delivery_notes
  has_many :delivery_items
  has_many :docuvita_documents, as: :documentable, dependent: :destroy

  # before_destroy :purge_attached_files
  # before_destroy :cleanup_delivery_items

  validates :delivery_date, presence: true
  validates :order_number, presence: true, uniqueness: true
  validates :supplier_name, presence: true
  validates :delivery_note_number, presence: true

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    left_joins(:project, :work_location, :user, :delivery_items)
      .where("incoming_deliveries.delivery_note_number LIKE :search OR
        incoming_deliveries.order_number LIKE :search OR
        incoming_deliveries.supplier_name LIKE :search OR
        projects.name LIKE :search OR
        projects.project_number LIKE :search OR
        work_locations.key LIKE :search OR
        work_locations.name LIKE :search OR
        work_locations.location_type LIKE :search OR
        users.first_name LIKE :search OR
        users.last_name LIKE :search OR
        delivery_items.tag_number LIKE :search OR
        delivery_items.batch_number LIKE :search OR
        delivery_items.item_description LIKE :search OR
        delivery_items.specifications LIKE :search OR
        delivery_items.delivery_note_position LIKE :search OR
        delivery_items.quantity_check_status LIKE :search OR
        delivery_items.dimension_check_status LIKE :search OR
        delivery_items.visual_check_status LIKE :search OR
        delivery_items.vt2_check_status LIKE :search OR
        delivery_items.ra_check_status LIKE :search OR
        delivery_items.on_hold_status LIKE :search",
        search: term
      ).distinct
  }

  def on_hold?
    on_hold_status == "On Hold"
  end

  def can_complete?
    delivery_items.where(completed: false).none?
  end

  def update_completion_status
    update(completed: all_checks_passed?)
  end

  def all_checks_passed?
    # First check if incoming delivery is on hold
    return false if on_hold_status == "On Hold"

    # Then check if any delivery items have failed status or are on hold
    delivery_items.each do |item|
      next unless item.present?

      # Check if delivery item is on hold
      return false if item.on_hold_status == "On Hold"

      check_statuses = [
        item.quantity_check_status,
        item.dimension_check_status,
        item.visual_check_status,
        item.vt2_check_status,
        item.ra_check_status
      ].compact

      # If any status is Failed, return false
      return false if check_statuses.any? { |status| status == "Failed" }
    end

    return false if delivery_items.map(&:completed).any?(false)

    true
  end

  # Returns docuvita documents that are on_hold_images
  def on_hold_images
    docuvita_documents.where(document_type: "on_hold_image")
  end
  alias_method :on_hold_documents, :on_hold_images

  # Check if the delivery is on hold
  def on_hold?
    on_hold_status == "On Hold"
  end

  # Returns docuvita documents that are delivery_notes
  def delivery_notes
    docuvita_documents.where(document_type: "delivery_note_pdf")
  end

  private

  # def purge_attached_files
  #   delivery_notes.purge_later if delivery_notes.attached?
  # end

  # def cleanup_delivery_items
  #   delivery_items.destroy_all
  # end
end
