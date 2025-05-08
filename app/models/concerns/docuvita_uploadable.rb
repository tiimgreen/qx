module DocuvitaUploadable
  extend ActiveSupport::Concern

  included do
    has_many :docuvita_documents, as: :documentable, dependent: :destroy
    accepts_nested_attributes_for :docuvita_documents, allow_destroy: true
  end

  def upload_pdf_to_docuvita(file_io, original_filename, options = {})
    begin
      uploader = DocuvitaUploader.new
      qr_position = options.delete(:qr_position)
      content_type = file_io.content_type
      content = file_io.read
      byte_size = content.bytesize
      checksum = Digest::MD5.base64digest(content)
      file_io.rewind

      # Determine document type based on the model
      doc_type = case self.class.name
      when "Isometry"
                  "isometry_pdf"
      when "MaterialCertificate"
                  "material_certificate_pdf"
      when "DeliveryNote"
                  "delivery_note_pdf"
      else
                  "isometry_pdf" # fallback to isometry_pdf as it's most common
      end

      filename = if respond_to?(:line_id)
                  "#{line_id}_#{doc_type}.pdf"
      else
                  "#{id}_#{doc_type}.pdf"
      end

      # Process the PDF with QR code if position is specified
      if qr_position.present?
        # Create a temporary document to use QrCodeable methods
        temp_doc = docuvita_documents.build(
          document_type: doc_type,
          filename: original_filename,
          content_type: content_type,
          qr_position: qr_position
        )
        processed_content = temp_doc.process_pdf_with_qr(content)
        byte_size = processed_content.bytesize
        checksum = Digest::MD5.base64digest(processed_content)
        file_io = StringIO.new(processed_content)
        file_io.set_encoding("ASCII-8BIT") # Ensure binary encoding for PDF
      end

      # Upload to Docuvita
      result = uploader.upload_io(
        file_io,
        filename,
        {
          voucher_number: respond_to?(:line_id) ? line_id : id.to_s,
          transaction_key: project.project_number,
          document_type: doc_type.titleize,
          description: "#{doc_type.titleize} for #{self.class.name}: #{id} and project: #{project.project_number}"
        }.merge(options)
      )

      # Create the document record after successful upload
      docuvita_documents.create!(
        docuvita_object_id: result[:object_id],
        document_type: doc_type,
        filename: filename,
        content_type: content_type,
        qr_position: qr_position,
        byte_size: byte_size,
        checksum: checksum,
        metadata: {
          response: result[:response]
        }
      )

      ProjectLog.info("PDF successfully uploaded to Docuvita",
                    source: "#{self.class.name}#upload_pdf_to_docuvita",
                    metadata: {
                      filename: original_filename
                    })
    rescue => e
      ProjectLog.error("Failed to upload PDF to Docuvita",
                      source: "#{self.class.name}#upload_pdf_to_docuvita",
                      details: e.message,
                      metadata: {
                        filename: original_filename,
                        content_type: file_io.content_type,
                        backtrace: e.backtrace.first(5)
                      })
      raise e
    end
  end

  def upload_image_to_docuvita(file_io, filename, type, options = {})
    begin
      # Check if this is an image file
      is_image = file_io.content_type&.start_with?("image/") ||
                %w[.jpg .jpeg .png .gif .bmp .tiff].include?(File.extname(filename).downcase)

      unless is_image
        ProjectLog.error("Invalid file type for upload_image_to_docuvita",
                      source: "#{self.class.name}#upload_image_to_docuvita",
                      metadata: {
                        filename: filename,
                        content_type: file_io.content_type
                      })
        raise "File must be an image type for upload_image_to_docuvita method"
      end

      uploader = DocuvitaUploader.new
      temp_image = Tempfile.new([ "image", File.extname(filename) ])
      temp_pdf = Tempfile.new([ "image_converted", ".pdf" ])

      begin
        # Write image to temp file
        file_io.rewind
        temp_image.binmode
        temp_image.write(file_io.read)
        temp_image.close

        # Convert to PDF using MiniMagick/ImageMagick
        require "mini_magick"

        image = MiniMagick::Image.open(temp_image.path)
        image.format "pdf"
        image.write temp_pdf.path

        # Upload the PDF instead of the image
        pdf_filename = if respond_to?(:line_id)
                        "#{line_id}_#{type}.pdf"
        else
                        "#{id}_#{type}.pdf"
        end

        # Ensure type is one of the valid document types
        doc_type = case type.to_s
        when /rt/i
                    "rt_image"
        when /vt/i
                    "vt_image"
        when /pt/i
                    "pt_image"
        when /hold/i
                    "on_hold_image"
        else
                    "on_hold_image" # fallback
        end

        # Upload the converted PDF
        result = uploader.upload_io(
          File.open(temp_pdf.path, "rb"),
          pdf_filename,
          {
            voucher_number: respond_to?(:line_id) ? line_id : id.to_s,
            transaction_key: project.project_number,
            document_type: "Image",
            description: "#{type} image (PDF converted) for #{self.class.name}: #{id} and project: #{project.project_number} and original filename: #{filename}"
          }.merge(options)
        )

        # Create a record of the uploaded document
        docuvita_documents.create!(
          docuvita_object_id: result[:object_id],
          document_type: doc_type,
          filename: pdf_filename,
          content_type: "application/pdf",
          metadata: {
            response: result[:response],
            original_content_type: file_io.content_type,
            converted_from_image: true
          }
        )

      ensure
        # Clean up temp files
        temp_image.unlink if temp_image && File.exist?(temp_image.path)
        temp_pdf.unlink if temp_pdf && File.exist?(temp_pdf.path)
      end

      ProjectLog.info("Document successfully uploaded to Docuvita",
                    source: "#{self.class.name}#upload_image_to_docuvita",
                    metadata: {
                      filename: filename,
                      type: type
                    })
    rescue => e
      ProjectLog.error("Failed to upload image to Docuvita",
                      source: "#{self.class.name}#upload_image_to_docuvita",
                      details: e.message,
                      metadata: {
                        filename: filename,
                        content_type: file_io.content_type,
                        backtrace: e.backtrace.first(5)
                      })
      raise e
    end
  end
end
