module QrCodeable
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  private

  def process_pdf_with_qr(pdf_attachment)
    Rails.logger.info "Starting PDF processing for attachment: #{pdf_attachment.filename}"

    # Create temporary files
    qr_temp_file = Tempfile.new([ "qr", ".png" ])
    pdf_temp_file = Tempfile.new([ "processed", ".pdf" ])
    input_pdf_file = Tempfile.new([ "input", ".pdf" ])

    begin
      # Generate QR code
      Rails.logger.info "Generating QR code"
      qr_code_url = project_isometry_url(project, self, locale: I18n.locale)
      Rails.logger.info "Generated QR URL: #{qr_code_url}"

      generate_qr_code_image(qr_code_url, qr_temp_file.path)

      # Download and save the original PDF
      Rails.logger.info "Downloading original PDF"
      pdf_attachment.blob.open do |tempfile|
        FileUtils.copy_file(tempfile.path, input_pdf_file.path)
      end

      # Get PDF dimensions from the first page
      reader = PDF::Reader.new(input_pdf_file.path)
      page = reader.pages.first
      page_width = page.width
      page_height = page.height
      Rails.logger.info "PDF dimensions: #{page_width}x#{page_height}"

      # Create new PDF with QR code overlay
      add_qr_code_to_pdf(
        input_pdf_file.path,
        pdf_temp_file.path,
        qr_temp_file.path,
        page_width,
        page_height
      )

      Rails.logger.info "PDF processing completed"
      pdf_temp_file
    rescue => e
      Rails.logger.error "Error processing PDF: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    ensure
      # Clean up temporary files
      qr_temp_file.close
      qr_temp_file.unlink
      input_pdf_file.close
      input_pdf_file.unlink
    end
  end

  def generate_qr_code_image(url, output_path)
    qr = RQRCode::QRCode.new(url)
    qr.as_png(
      bit_depth: 1,
      border_modules: 0,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: output_path,
      fill: "white",
      module_px_size: 8,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 200
    ).save(output_path)
  end

  def add_qr_code_to_pdf(input_path, output_path, qr_path, page_width, page_height)
    # Calculate QR code position (top-right corner with 20pt padding)
    qr_width = 200  # QR code width in points
    qr_height = 200 # QR code height in points
    x_position = page_width - qr_width - 20
    y_position = page_height - qr_height - 20
    Rails.logger.info "Adding QR code at position: #{x_position},#{y_position}"

    # Create new PDF with QR code overlay
    Prawn::Document.generate(output_path, template: input_path) do |pdf|
      pdf.go_to_page(1)
      pdf.image qr_path,
               at: [ x_position, y_position ],
               width: qr_width,
               height: qr_height
    end
  end
end
