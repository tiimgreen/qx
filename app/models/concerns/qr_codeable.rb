module QrCodeable
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers
  end

  private

  def process_pdf_with_qr(pdf_attachment)
    Rails.logger.info "Starting PDF processing for attachment: #{pdf_attachment.filename}"
    Rails.logger.info "Current QR position setting: #{qr_position}"

    # Create temporary files
    qr_temp_file = Tempfile.new([ "qr", ".png" ])
    pdf_temp_file = Tempfile.new([ "processed", ".pdf" ])
    input_pdf_file = Tempfile.new([ "input", ".pdf" ])

    begin
      # Generate QR code
      Rails.logger.info "Generating QR code"
      qr_code_url = qr_redirect_url(isometry, locale: I18n.locale)
      Rails.logger.info "Generated QR URL: #{qr_code_url}"

      generate_qr_code_image(qr_code_url, qr_temp_file.path)
      Rails.logger.info "QR code image generated successfully"

      # Ensure the blob is persisted and analyzed
      pdf_attachment.blob.analyze if !pdf_attachment.blob.analyzed?

      # Download and save the original PDF
      Rails.logger.info "Downloading original PDF"
      pdf_attachment.open do |tempfile|
        FileUtils.copy_file(tempfile.path, input_pdf_file.path)
      end
      Rails.logger.info "Original PDF downloaded successfully"

      # Get PDF dimensions from the first page
      reader = PDF::Reader.new(input_pdf_file.path)
      page = reader.pages.first
      @page_width = page.width
      @page_height = page.height
      Rails.logger.info "PDF dimensions: #{@page_width}x#{@page_height} points"

      # Create new PDF with QR code overlay
      Rails.logger.info "Adding QR code to PDF"
      add_qr_code_to_pdf(
        input_path: input_pdf_file.path,
        output_path: pdf_temp_file.path,
        qr_path: qr_temp_file.path
      )

      Rails.logger.info "PDF processing completed successfully"
      pdf_temp_file
    rescue => e
      Rails.logger.error "Error processing PDF: #{e.message}"
      Rails.logger.error "Error occurred at:"
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
    Rails.logger.info "Generating QR code for URL: #{url}"
    qrcode = RQRCode::QRCode.new(url, size: 4, level: :l)

    # Generate PNG with optimized settings for smaller size
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 1,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: output_path,
      fill: "white",
      module_px_size: 3,
      resize_exactly_to: 120
    )
    Rails.logger.info "QR code PNG generated at: #{output_path}"
  end

  def add_qr_code_to_pdf(input_path:, output_path:, qr_path:)
    Rails.logger.info "Adding QR code at position: #{qr_position}"
    Rails.logger.info "Page dimensions: #{@page_width}x#{@page_height}"

    begin
      Prawn::Document.generate(output_path,
                             template: input_path,
                             page_size: [ @page_width, @page_height ]) do |pdf|
        pdf.go_to_page(1)

        # Convert measurements
        # 1 millimeter = 2.83465 points in PDF
        mm_to_points = 2.83465

        # QR code size (40 points)
        qr_size = 40

        # 5mm margin converted to points
        margin_mm = 15
        margin_pts = margin_mm * mm_to_points

        # Calculate position based on the PDF coordinate system (origin at bottom-left)
        x, y = case qr_position.to_s
        when "bottom_left"
          [ margin_pts, margin_pts ]
        when "bottom_right"
          [ @page_width - margin_pts - qr_size, margin_pts ]
        when "top_left"
          [ margin_pts, @page_height - margin_pts - qr_size ]
        when "top_right"
          [ @page_width - margin_pts - qr_size, @page_height - (margin_pts - 12 * mm_to_points) - qr_size ]
        else
          [ margin_pts, margin_pts ]
        end

        Rails.logger.info "Final QR position: x=#{x}, y=#{y}, size=#{qr_size}, margin=#{margin_pts}pts (#{margin_mm}mm)"

        pdf.image qr_path,
                 at: [ x, y ],
                 width: qr_size,
                 height: qr_size
      end
      Rails.logger.info "QR code successfully added to PDF"
    rescue => e
      Rails.logger.error "Failed to add QR code to PDF: #{e.message}"
      raise
    end
  end

  def calculate_qr_position(position)
    # This method is now only used for logging purposes
    margin_pts = 10
    qr_size = 40

    case position.to_s
    when "bottom_left"
      [ margin_pts, margin_pts ]
    when "bottom_right"
      [ @page_width - margin_pts - qr_size, margin_pts ]
    when "top_left"
      [ margin_pts, @page_height - margin_pts - qr_size ]
    when "top_right"
      [ @page_width - margin_pts - qr_size, @page_height - margin_pts - qr_size ]
    else
      [ margin_pts, margin_pts ]
    end
  end

  def page_width
    @page_width
  end

  def page_height
    @page_height
  end
end
