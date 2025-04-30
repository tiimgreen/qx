class DocuvitaDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_document

  def download
    # Create uploader
    uploader = DocuvitaUploader.new

    # Download the document
    content = uploader.download_document(@document.docuvita_object_id)

    # Determine content type
    content_type = @document.content_type || determine_content_type(@document)

    # Determine filename
    filename = @document.filename || "document-#{@document.id}#{File.extname(@document.filename.to_s)}"

    # Send the file - use attachment disposition to download
    send_data content,
              type: content_type,
              disposition: "attachment",
              filename: filename
  end

  def view
    # Create uploader
    uploader = DocuvitaUploader.new

    # Download the document
    content = uploader.download_document(@document.docuvita_object_id)

    # Determine content type
    content_type = @document.content_type || determine_content_type(@document)

    # Determine filename
    filename = @document.filename || "document-#{@document.id}#{File.extname(@document.filename.to_s)}"

    # Send the file with inline disposition to display in browser
    send_data content,
              type: content_type,
              disposition: "inline",
              filename: filename
  end

  private

  def set_document
    @document = DocuvitaDocument.find(params[:id])
  end

  def determine_content_type(document)
    if document.document_type == "isometry_pdf"
      "application/pdf"
    elsif document.document_type.include?("image")
      # Try to determine image type from filename if available
      if document.filename.present?
        case File.extname(document.filename).downcase
        when ".jpg", ".jpeg"
          "image/jpeg"
        when ".png"
          "image/png"
        when ".gif"
          "image/gif"
        else
          "image/jpeg" # Default to JPEG if unknown
        end
      else
        "image/jpeg" # Default to JPEG if no filename
      end
    else
      "application/octet-stream" # Default binary type
    end
  end
end
