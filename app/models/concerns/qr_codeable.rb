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
      qr_code_url = qr_redirect_url(isometry, locale: I18n.locale)
      Rails.logger.info "Generated QR URL: #{qr_code_url}"

      generate_qr_code_image(qr_code_url, qr_temp_file.path)

      # Ensure the blob is persisted and analyzed
      pdf_attachment.blob.analyze if !pdf_attachment.blob.analyzed?

      # Download and save the original PDF
      Rails.logger.info "Downloading original PDF"
      pdf_attachment.open do |tempfile|
        FileUtils.copy_file(tempfile.path, input_pdf_file.path)
      end

      # Get PDF dimensions from the first page
      reader = PDF::Reader.new(input_pdf_file.path)
      page = reader.pages.first
      @page_width = page.width
      @page_height = page.height
      Rails.logger.info "PDF dimensions: #{@page_width}x#{@page_height}"

      # Create new PDF with QR code overlay
      add_qr_code_to_pdf(
        input_path: input_pdf_file.path,
        output_path: pdf_temp_file.path,
        qr_path: qr_temp_file.path
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
    qrcode = RQRCode::QRCode.new(url, size: 4, level: :l)  # Reduced size, lowest error correction for smaller code

    # Generate PNG with optimized settings for smaller size
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 1,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: output_path,
      fill: "white",
      module_px_size: 3,  # Reduced for smaller final size
      resize_exactly_to: 120  # Reduced final size
    )
  end

  def add_qr_code_to_pdf(input_path:, output_path:, qr_path:)
    # Calculate coordinates based on position
    x, y = calculate_qr_position(qr_position)

    Rails.logger.info "Adding QR code at position: #{x},#{y} (#{qr_position})"

    # Create new PDF with QR code overlay
    Prawn::Document.generate(output_path, template: input_path) do |pdf|
      pdf.go_to_page(1)
      pdf.image qr_path,
               at: [ x, y ],
               width: 40,
               height: 40
    end
  end

  def calculate_qr_position(position)
    margin = 10
    qr_size = 40

    coords = case position.to_s
    when "top_right"
      x = -25
      y = 1145
      [ x, y ]
    when "top_left" # nord right
      x = 0
      y = 100
      [ x, y ]
    when "bottom_right"
      x = 755
      y = 1145
      [ x, y ]
    when "bottom_left"
      x = 760
      y = 10
      [ x, y ]
    else
      x = @page_width - qr_size - margin
      y = @page_height - qr_size - margin
      [ x, y ]
    end

    coords
  end

  def page_width
    @page_width
  end

  def page_height
    @page_height
  end
end
