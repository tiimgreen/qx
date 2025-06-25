class MaterialCertificate < ApplicationRecord
  include DocuvitaUploadable

  has_many :isometry_material_certificates, dependent: :delete_all
  has_many :isometries, through: :isometry_material_certificates
  has_many :weldings_as_certificate, class_name: "Welding", foreign_key: "material_certificate_id", dependent: :nullify
  has_many :weldings_as_certificate1, class_name: "Welding", foreign_key: "material_certificate1_id", dependent: :nullify

  # need for migration
  # has_one_attached :certificate_file

  validates :certificate_number,
            presence: { message: :blank },
            uniqueness: { case_sensitive: false, message: :taken }
  validates :batch_number, presence: true

  validates :issue_date, presence: true

  before_validation :upcase_certificate_number

  scope :pending, -> { where(status: "pending") }

  scope :search_by_term, ->(term) {
    where("LOWER(certificate_number) LIKE :term OR LOWER(batch_number) LIKE :term OR LOWER(issuer_name) LIKE :term OR LOWER(line_id) LIKE :term OR LOWER(description) LIKE :term",
          term: "%#{term&.downcase}%")
  }

  # Uploads the given certificate file to Docuvita
  # @param file [ActionDispatch::Http::UploadedFile] The uploaded file object
  # @param original_filename [String] The original name of the file
  # @return [DocuvitaDocument] The created DocuvitaDocument record
  # @raise [StandardError] If upload fails or required data is missing
  def upload_certificate_to_docuvita(file, original_filename)
    unless certificate_number.present?
      raise StandardError, "Certificate Number is missing, cannot upload to Docuvita."
    end

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

    # Use the DocuvitaUploadable concern's upload_pdf_to_docuvita method
    sector_name = "material_certificate"

    # Create options hash for the upload
    options = {
      voucher_number: certificate_number,
      transaction_key: base_project_number,
      document_type: "MaterialCertificate",
      voucher_type: "material_certificate",
      description: certificate_metadata
    }

    # Upload the file using the concern's method
    upload_pdf_to_docuvita(file, original_filename, "material_certificate", sector_name, options)
  rescue StandardError => e
    Rails.logger.error "Docuvita upload failed for Material Certificate ##{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Re-raise the error to be caught by the controller
    raise StandardError, "Failed to upload certificate to Docuvita: #{e.message}"
  end

  def material_certificates
    docuvita_documents.where(document_sub_type: "material_certificate")
  end

  private

  def upcase_certificate_number
    self.certificate_number = certificate_number.upcase if certificate_number.present?
  end
end
