class IncomingDelivery < ApplicationRecord
  belongs_to :project
  belongs_to :work_location
  belongs_to :user, optional: true
  has_many_attached :delivery_notes
  has_many :delivery_items
  has_many :docuvita_documents, as: :documentable

  before_destroy :purge_attached_files
  before_destroy :cleanup_delivery_items

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

  # Uploads the given delivery note file to Docuvita
  # @param file [ActionDispatch::Http::UploadedFile] The uploaded file object
  # @param original_filename [String] The original name of the file
  # @return [DocuvitaDocument] The created DocuvitaDocument record
  # @raise [StandardError] If upload fails or required data is missing
  def upload_delivery_note_to_docuvita(file, original_filename)
    # Ensure required attributes are present
    unless delivery_note_number.present?
      raise StandardError, "Delivery Note Number is missing, cannot upload to Docuvita."
    end

    # Instantiate uploader with correct object type ID for delivery notes
    uploader = DocuvitaUploader.new(object_type_id: 29)

    # Prepare metadata hash for DocuvitaDocument
    delivery_metadata = {
      delivery_note_number: delivery_note_number,
      order_number: order_number,
      supplier_name: supplier_name,
      project_id: project_id,
      original_filename: original_filename,
      upload_context: "manual_form"
    }

    # Prepare Docuvita API payload
    docuvita_filename = "#{delivery_note_number}_dn.pdf"
    api_description = delivery_metadata
    voucher_number = delivery_note_number
    transaction_key = project&.project_number || "UNKNOWN_PROJECT"
    local_document_type = "delivery_note_pdf"

    # Perform upload using tempfile
    object_id = nil
    begin
      File.open(file.tempfile.path, "rb") do |tempfile_handle|
        upload_result = uploader.upload_file(
          tempfile_handle.path,
          {
            name: docuvita_filename,
            description: api_description,
            voucher_number: voucher_number,
            transaction_key: transaction_key,
            version_original_filename: original_filename,
            document_type: "DeliveryNote"
          }
        )
        object_id = upload_result[:object_id]
      end

      unless object_id
        raise StandardError, "Docuvita upload failed: No object_id received."
      end

      # Create DocuvitaDocument record on success
      docuvita_doc = docuvita_documents.create!(
        docuvita_object_id: object_id,
        document_type: local_document_type,
        metadata: delivery_metadata,
        filename: docuvita_filename,
        content_type: file.content_type,
        byte_size: file.size
      )

      Rails.logger.info "Successfully uploaded Delivery Note ##{id} to Docuvita (ObjectID: #{object_id})"
      docuvita_doc

    rescue StandardError => e
      Rails.logger.error "Docuvita upload failed for Delivery Note ##{id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Re-raise the error to be caught by the controller
      raise StandardError, "Failed to upload delivery note to Docuvita: #{e.message}"
    end
  end

  private

  def purge_attached_files
    delivery_notes.purge_later if delivery_notes.attached?
  end

  def cleanup_delivery_items
    delivery_items.destroy_all
  end
end
