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

  def destroy
    @document = DocuvitaDocument.find(params[:id])

    if @document.destroy
      respond_to do |format|
        format.html {
          redirect_back(fallback_location: root_path,
                       notice: t("common.messages.deleted", model: t("activerecord.models.docuvita_document")))
        }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html {
          redirect_back(fallback_location: root_path,
                       alert: t("common.messages.delete_error", model: t("activerecord.models.docuvita_document")))
        }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
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
