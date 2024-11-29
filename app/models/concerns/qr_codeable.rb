module QrCodeable
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  def generate_qr_code_url
    url = project_isometry_url(
      project_id: project_id,
      id: id,
      locale: I18n.locale,
      host: Rails.application.config.action_mailer.default_url_options[:host],
      port: Rails.application.config.action_mailer.default_url_options[:port]
    )
    Rails.logger.info "Generated QR URL: #{url}"
    url
  end

  def generate_qr_code
    qrcode = RQRCode::QRCode.new(generate_qr_code_url)
    qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 8,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 200
    )
  end

  def add_qr_code_to_image(image)
    # Convert QR code to PNG
    qr_code_png = generate_qr_code
    qr_temp_file = Tempfile.new([ "qr", ".png" ])
    qr_code_png.save(qr_temp_file.path)

    # Process the original image
    image_temp = MiniMagick::Image.new(image.tempfile.path)

    # Calculate position (top right corner, 20px padding)
    x_position = image_temp.width - 220  # QR size (200) + padding (20)
    y_position = 20

    # Composite QR code onto the image
    result = image_temp.composite(MiniMagick::Image.new(qr_temp_file.path)) do |c|
      c.compose "Over"
      c.geometry "+#{x_position}+#{y_position}"
    end

    # Clean up temp files
    qr_temp_file.close
    qr_temp_file.unlink

    # Return the processed image
    result
  end

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

      qr = RQRCode::QRCode.new(qr_code_url)
      qr.as_png(
        bit_depth: 1,
        border_modules: 0,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: "black",
        file: qr_temp_file.path,
        fill: "white",
        module_px_size: 8,
        resize_exactly_to: false,
        resize_gte_to: false,
        size: 200
      ).save(qr_temp_file.path)

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

      # Calculate QR code position (top-right corner with 20pt padding)
      qr_width = 200  # QR code width in points
      qr_height = 200 # QR code height in points
      x_position = page_width - qr_width - 20
      y_position = page_height - qr_height - 20
      Rails.logger.info "Adding QR code at position: #{x_position},#{y_position}"

      # Create new PDF with QR code overlay
      Prawn::Document.generate(pdf_temp_file.path, template: input_pdf_file.path) do |pdf|
        # Move to the first page
        pdf.go_to_page(1)
        
        # Add QR code image
        pdf.image qr_temp_file.path, 
                 at: [x_position, y_position],
                 width: qr_width,
                 height: qr_height
      end

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
end
