class IsometryDocument < ApplicationRecord
  include QrCodeable

  belongs_to :isometry
  has_one_attached :pdf

  validates :qr_position, inclusion: {
    in: %w[top_left top_right bottom_left bottom_right],
    allow_nil: true
  }

  after_commit :process_pdf, on: [ :create, :update ]

  private

  def process_pdf
    return unless pdf.attached?
    return if @processing_pdf # Add guard to prevent recursive processing

    @processing_pdf = true
    begin
      Rails.logger.info "Processing PDF for isometry document #{id}"

      # Process the PDF with QR code
      processed_file = process_pdf_with_qr(pdf)

      # Create new blob and attach it
      new_blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(processed_file.path),
        filename: pdf.filename.to_s,
        content_type: "application/pdf"
      )

      # Replace the old attachment with the new one
      pdf.update!(blob: new_blob)

      # Clean up
      processed_file.close
      processed_file.unlink

      Rails.logger.info "PDF processing completed"
    rescue => e
      Rails.logger.error "Error processing PDF: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    ensure
      @processing_pdf = false
    end
  end

  # Required by QrCodeable concern to access the project
  def project
    isometry.project
  end
end
