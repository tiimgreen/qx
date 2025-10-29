module DocuvitaUploadable
  extend ActiveSupport::Concern

  # voucher_number: respond_to?(:line_id) ? line_id : id.to_s,
  # transaction_key: project.project_number,

  included do
    has_many :docuvita_documents, as: :documentable, dependent: :destroy
    accepts_nested_attributes_for :docuvita_documents, allow_destroy: true
  end

  def upload_pdf_to_docuvita(file_io, original_filename, type, sector_name, options = {})
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
                  "isometry"
      when "MaterialCertificate"
                  "material_certificate"
      when "IncomingDelivery"
                  "delivery_note"
      else
                  "isometry"
      end

      # Ensure type is one of the valid document types
      doc_sub_type = determine_document_type(type)

      filename = "#{sector_name}.pdf"
      web_filename = "#{doc_sub_type}.pdf"

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
          transaction_key: base_project_number,
          document_type: sector_name,
          voucher_type: doc_sub_type,
          description: "#{doc_sub_type.titleize} for #{self.class.name}: #{id}#{respond_to?(:project) && project ? " and project: #{project.project_number}" : ""}"
        }.merge(options)
      )

      # Create the document record after successful upload
      docuvita_documents.create!(
        docuvita_object_id: result[:object_id],
        document_type: sector_name,
        document_sub_type: doc_sub_type,
        filename: web_filename,
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

  def upload_image_to_docuvita(file_io, filename, type, sector_name, options = {})
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
        raise I18n.t("errors.messages.invalid_image_type", filename: filename)
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
        pdf_filename = "#{sector_name}.pdf"

        # Ensure type is one of the valid document types
        doc_type = determine_document_type(type)
        web_filename = "#{doc_type}.pdf"

        # Upload the converted PDF
        result = uploader.upload_io(
          File.open(temp_pdf.path, "rb"),
          pdf_filename,
          {
            voucher_number: respond_to?(:line_id) ? line_id : id.to_s,
            transaction_key: base_project_number,
            document_type: sector_name,
            voucher_type: doc_type,
            description: "#{type} for #{self.class.name}: #{id} and project: #{project.project_number} and original filename: #{filename}"
          }.merge(options)
        )

        # Create a record of the uploaded document
        docuvita_documents.create!(
          docuvita_object_id: result[:object_id],
          document_type: sector_name,
          document_sub_type: doc_type,
          filename: web_filename,
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

  def base_project_number
    return "" if !respond_to?(:project) || project.nil?

    project_num = project.project_number.gsub(" ", "/")
    project_num.include?("/") ? project_num.split("/").first : project_num
  end

  # Determine the document type based on the provided type string
  def determine_document_type(type)
    case type.to_s
    when /material_certificate/i
                "material_certificate"
    when /rt_check/i, /rt2_check/i
                "rt_check_image"
    when /vt2_check/i
                "vt2_check_image"
    when /pt2_check/i
                "pt2_check_image"
    when /visual_check/i
                "visual_check_image"
    when /isometry/i
                "isometry"
    when /delivery_note/i
                "delivery_note"
    when /check_spools/i
                "check_spools_image"
    when /quantity_check/i
                "quantity_check_image"
    when /dimension_check/i
                "dimension_check_image"
    when /ra_check/i
                "ra_check_image"
    when /on_site/i
                "on_site_image"
    when /rt/i
                "rt_image"
    when /vt_pictures/i
                "vt_pictures_image"
    when /vt/i
                "vt_image"
    when /pt/i
                "pt_image"
    when /hold/i
                "on_hold_image"
    else
                "on_hold_image"
    end
  end
end
