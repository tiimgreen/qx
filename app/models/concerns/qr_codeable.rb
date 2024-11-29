module QrCodeable
  extend ActiveSupport::Concern

  def generate_qr_code_url
    url = Rails.application.routes.url_helpers.project_isometry_url(
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
    converted_image_file = Tempfile.new([ "converted", ".png" ])

    begin
      # Download the PDF file to a temporary location
      pdf_attachment.blob.open do |file|
        Rails.logger.info "Copying PDF to temporary file: #{input_pdf_file.path}"
        FileUtils.copy_file(file.path, input_pdf_file.path)
      end

      # Generate and save QR code
      Rails.logger.info "Generating QR code"
      qr_code_png = generate_qr_code
      qr_code_png.save(qr_temp_file.path)

      # Convert PDF to image
      Rails.logger.info "Converting PDF to image"
      MiniMagick::Tool::Convert.new do |convert|
        convert << input_pdf_file.path + "[0]"  # [0] means first page only
        convert.resize("3000x3000")
        convert.quality("100")
        convert.density("300")
        convert.background("white")
        convert.alpha("remove")
        convert << converted_image_file.path
      end

      # Load the converted image
      image = MiniMagick::Image.new(converted_image_file.path)
      Rails.logger.info "Image dimensions: #{image.width}x#{image.height}"

      # Calculate QR code position (top right corner with padding)
      x_position = image.width - 220  # QR size (200) + padding (20)
      y_position = 20

      Rails.logger.info "Adding QR code at position: #{x_position},#{y_position}"

      # Add QR code to the image
      result = image.composite(MiniMagick::Image.new(qr_temp_file.path)) do |c|
        c.compose "Over"
        c.geometry "+#{x_position}+#{y_position}"
      end

      # Convert back to PDF
      Rails.logger.info "Converting back to PDF"
      result.format "pdf"
      result.write pdf_temp_file.path

      # If original PDF had multiple pages, merge them
      page_count = PDF::Reader.new(input_pdf_file.path).page_count
      Rails.logger.info "Original PDF has #{page_count} pages"

      if page_count > 1
        Rails.logger.info "Merging multiple pages"
        combined_pdf = CombinePDF.new
        # Add first page with QR code
        combined_pdf << CombinePDF.load(pdf_temp_file.path)

        # Add remaining pages from original PDF
        original_pdf = CombinePDF.load(input_pdf_file.path)
        original_pdf.pages[1..-1].each do |page|
          combined_pdf << page
        end

        combined_pdf.save pdf_temp_file.path
      end

      Rails.logger.info "PDF processing completed"
      # Return processed PDF file
      pdf_temp_file
    rescue => e
      Rails.logger.error "Error processing PDF: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    ensure
      qr_temp_file.close
      qr_temp_file.unlink
      input_pdf_file.close
      input_pdf_file.unlink
      converted_image_file.close
      converted_image_file.unlink
    end
  end
end
