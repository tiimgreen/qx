# app/models/docuvita_document.rb
class DocuvitaDocument < ApplicationRecord
  include QrCodeable

  belongs_to :documentable, polymorphic: true

  validates :docuvita_object_id, presence: true
  validates :document_type, presence: true

  # Document types
  DOCUMENT_TYPES = %w[isometry rt_image vt_image vt_pictures_image pt_image on_hold_image qr_code material_certificate delivery_note visual_check_image vt2_check_image pt2_check_image rt_check_image on_site_image check_spools_image quantity_check_image dimension_check_image ra_check_image prefabrication work_preparation welding final_inspection transport site_delivery site_assembly as_built test_pack incoming_delivery delivery_item].freeze
  VALID_QR_POSITIONS = %w[top_left top_right bottom_left bottom_right].freeze

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }
  validates :qr_position, inclusion: { in: VALID_QR_POSITIONS, allow_nil: true }

  # Scope to find documents by type
  scope :of_type, ->(type) { where(document_type: type) }

  def project
    documentable.try(:project)
  end

  def qr_code_url
    return unless documentable.is_a?(Isometry)
    Rails.application.routes.url_helpers.qr_redirect_url(
      isometry_id: documentable.id,
      host: Rails.application.routes.default_url_options[:host]
    )
  end

  def download_content
    client = DocuvitaService::Client.new(
      DOCUVITA_CONFIG[:base_url],
      DOCUVITA_CONFIG[:session_guid]
    )
    pdf_content = client.get_document(docuvita_object_id)
    process_pdf_with_qr(pdf_content)
  end

  # Override process_pdf_with_qr to work with Docuvita
  def process_pdf_with_qr(pdf_content)
    return pdf_content unless qr_position.present?

    # Create temporary files
    qr_temp_file = Tempfile.new([ "qr", ".png" ])
    pdf_temp_file = Tempfile.new([ "processed", ".pdf" ])
    input_pdf_file = Tempfile.new([ "input", ".pdf" ])

    begin
      # Generate QR code
      current_url = qr_code_url
      generate_qr_code_image(current_url, qr_temp_file.path)

      # Write the PDF content to temp file
      File.binwrite(input_pdf_file.path, pdf_content)

      # Get PDF dimensions
      reader = PDF::Reader.new(input_pdf_file.path)
      page = reader.pages.first
      @page_width = page.width
      @page_height = page.height

      # Add QR code to PDF
      add_qr_code_to_pdf(
        input_path: input_pdf_file.path,
        output_path: pdf_temp_file.path,
        qr_path: qr_temp_file.path
      )

      # Return the processed PDF content
      File.read(pdf_temp_file.path)
    ensure
      qr_temp_file.close
      qr_temp_file.unlink
      pdf_temp_file.close
      pdf_temp_file.unlink
      input_pdf_file.close
      input_pdf_file.unlink
    end
  end
end
