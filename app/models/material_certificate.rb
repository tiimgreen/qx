class MaterialCertificate < ApplicationRecord
  has_many :isometry_material_certificates, dependent: :destroy
  has_many :isometries, through: :isometry_material_certificates
  has_many :weldings_as_certificate, class_name: "Welding", foreign_key: "material_certificate_id", dependent: :nullify
  has_many :weldings_as_certificate1, class_name: "Welding", foreign_key: "material_certificate1_id", dependent: :nullify
  has_many :docuvita_documents, as: :documentable, dependent: :destroy

  validates :certificate_number,
            presence: true,
            uniqueness: { case_sensitive: false, message: "already exists (case insensitive)" }
  validates :batch_number, presence: true
  validates :issue_date, presence: true

  before_validation :upcase_certificate_number

  scope :pending, -> { where(status: "pending") }

  scope :search_by_term, ->(term) {
    where("LOWER(certificate_number) LIKE :term OR LOWER(batch_number) LIKE :term OR LOWER(issuer_name) LIKE :term OR LOWER(line_id) LIKE :term",
          term: "%#{term&.downcase}%")
  }

  # Uploads the given certificate file to Docuvita
  # @param file [ActionDispatch::Http::UploadedFile] The uploaded file object
  # @param original_filename [String] The original name of the file
  # @return [DocuvitaDocument] The created DocuvitaDocument record
  # @raise [StandardError] If upload fails or required data is missing
  def upload_certificate_to_docuvita(file, original_filename)
    # Ensure required attributes are present
    unless certificate_number.present?
      raise StandardError, "Certificate Number is missing, cannot upload to Docuvita."
    end

    # Instantiate uploader
    uploader = DocuvitaUploader.new

    # Prepare metadata hash for DocuvitaDocument
    certificate_metadata = {
      certificate_number: certificate_number,
      batch_number: batch_number,
      issue_date: issue_date,
      issuer_name: issuer_name,
      description: description,
      line_id: line_id,
      original_filename: original_filename,
      upload_context: "manual_form"
    }

    # Prepare Docuvita API payload
    docuvita_filename = "#{certificate_number}_cert.pdf"
    api_description = certificate_metadata
    voucher_number = certificate_number
    transaction_key = ""
    docuvita_api_document_type = "MaterialCertificate"
    local_document_type = "material_certificate_pdf"

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
            document_type: docuvita_api_document_type,
            version_original_filename: original_filename
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
        metadata: certificate_metadata,
        filename: docuvita_filename,
        content_type: file.content_type,
        byte_size: file.size
      )

      Rails.logger.info "Successfully uploaded Material Certificate ##{id} to Docuvita (ObjectID: #{object_id})"
      docuvita_doc

    rescue StandardError => e
      Rails.logger.error "Docuvita upload failed for Material Certificate ##{id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # Re-raise the error to be caught by the controller
      raise StandardError, "Failed to upload certificate to Docuvita: #{e.message}"
    end
  end

  private

  def upcase_certificate_number
    self.certificate_number = certificate_number.upcase if certificate_number.present?
  end
end
