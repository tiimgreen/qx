class IncomingDelivery < ApplicationRecord
  belongs_to :project
  belongs_to :work_location
  belongs_to :user, optional: true
  has_many_attached :delivery_notes
  has_many :delivery_items, dependent: :destroy
  has_many :material_certificates, through: :delivery_items

  before_destroy :purge_attached_files

  validates :delivery_date, presence: true
  validates :order_number, presence: true, uniqueness: true
  validates :supplier_name, presence: true
  validates :delivery_note_number, presence: true

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    left_joins(:project)
      .where("incoming_deliveries.delivery_note_number LIKE :search OR
        incoming_deliveries.order_number LIKE :search OR
        incoming_deliveries.supplier_name LIKE :search OR
        projects.name LIKE :search OR
        projects.project_number LIKE :search",
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

  private

  def purge_attached_files
    delivery_notes.purge
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

    true
  end
end
