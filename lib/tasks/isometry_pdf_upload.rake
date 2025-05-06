# lib/tasks/docuvita2.rake
require "pathname"

namespace :docuvita do
  desc "Upload Isometry PDFs (from IsometryDocument) for a specific project to Docuvita. Usage: rails 'docuvita:upload_isometry_pdfs[project_id,limit]'"
  task :upload_isometry_pdfs, [ :project_id, :limit ] => :environment do |_task, args|
    project_id = args[:project_id]
    # Set a default limit or use the one from args, default to a high number if none provided
    upload_limit = args[:limit].present? ? args[:limit].to_i : 1_000_000 # Effectively no limit unless specified
    testing_limit = 5 # Define the specific limit for testing
    effective_limit = [ upload_limit, testing_limit ].min # Use the smaller of the argument or the hardcoded test limit

    unless project_id
      puts "ERROR: Project ID is required."
      puts "Usage: rails 'docuvita:upload_isometry_pdfs[your_project_id,optional_limit]'"
      abort
    end

    project = Project.find_by(id: project_id)
    unless project
      puts "ERROR: Project with ID #{project_id} not found."
      abort
    end

    project_display_name = project.project_number ? "#{project.name} (#{project.project_number})" : project.name
    puts "Starting Docuvita PDF upload for Project: #{project_display_name} (ID: #{project.id})"
    puts "Upload limit: #{effective_limit}"
    puts "--------------------------------------------------"

    uploader = DocuvitaUploader.new
    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    upload_attempts = 0
    limit_reached = false

    # Eager load project, its isometries, their isometry_documents (plural) with PDF attachments,
    # and any existing docuvita documents for the isometries.
    isometries = project.isometries.includes(:project, { isometry_documents: :pdf_attachment }, :docuvita_documents)

    isometries.find_in_batches(batch_size: 100) do |isometries_batch|
      puts "Processing batch of #{isometries_batch.size} isometries..."

      isometries_batch.each do |isometry|
        break if limit_reached

        puts "\nProcessing Isometry (Line ID: #{isometry.line_id || 'N/A'})... (Attempt ##{upload_attempts + 1})"

        # Ensure line_id and project_number exist for naming/metadata
        unless isometry.line_id.present? && isometry.project&.project_number.present?
          puts "  [SKIP] Isometry missing Line ID or Project Number required for Docuvita metadata."
          skipped_count += 1
          next
        end

        # Check and increment attempt counter
        if upload_attempts >= effective_limit
          puts "  [INFO] Reached upload limit of #{effective_limit}. Stopping."
          limit_reached = true
          break
        end
        upload_attempts += 1

        # Find the first associated IsometryDocument with an attached PDF
        iso_doc = isometry.isometry_documents.find { |doc| doc.pdf.attached? }
        unless iso_doc
          puts "  [SKIP] No IsometryDocument with an attached PDF found."
          skipped_count += 1
          next
        end

        pdf_blob = iso_doc.pdf.blob
        original_filename = pdf_blob.filename.to_s

        # Check if already uploaded to Docuvita for the Isometry
        existing_docuvita_doc = isometry.docuvita_documents.of_type("isometry_pdf").first
        if existing_docuvita_doc
          puts "  [SKIP] Already uploaded. Docuvita Object ID: #{existing_docuvita_doc.docuvita_object_id}"
          skipped_count += 1
          next
        end

        # Prepare for upload - Align naming and metadata
        docuvita_filename = "#{isometry.line_id}_isometry.pdf"
        description = "Isometry PDF with line_id: #{isometry.line_id} and project_number: #{isometry.project.project_number} and original filename: #{original_filename}"
        voucher_number = isometry.line_id
        transaction_key = isometry.project.project_number
        docuvita_api_document_type = "Isometry"
        local_document_type = "isometry_pdf"

        puts "  Uploading '#{original_filename}' (from IsometryDocument ##{iso_doc.id}) as '#{docuvita_filename}'..."

        begin
          iso_doc.pdf.open do |tempfile|
            upload_result = uploader.upload_file(
              tempfile.path,
              {
                name: docuvita_filename,
                description: description,
                voucher_number: voucher_number,
                transaction_key: transaction_key,
                document_type: docuvita_api_document_type,
                version_original_filename: original_filename
              }
            )

            object_id = upload_result[:object_id]

            if object_id
              DocuvitaDocument.create!(
                documentable: isometry,
                docuvita_object_id: object_id,
                document_type: local_document_type,
                filename: docuvita_filename,
                content_type: pdf_blob.content_type,
                byte_size: pdf_blob.byte_size,
                checksum: pdf_blob.checksum,
                qr_position: iso_doc.qr_position
              )
              puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{object_id}."
              ProjectLog.info("Docuvita upload success", source: "RakeTask",
                            metadata: { project_id: project.id,
                                      isometry_id: isometry.id,
                                      isometry_document_id: iso_doc.id,
                                      docuvita_object_id: object_id,
                                      filename: docuvita_filename })
              uploaded_count += 1
            else
              error_message = upload_result.dig(:response, "Error") || upload_result[:response].to_s
              puts "  [FAIL] Upload failed. Response: #{error_message}"
              ProjectLog.error("Docuvita upload failed", source: "RakeTask",
                             metadata: { project_id: project.id,
                                       isometry_id: isometry.id,
                                       isometry_document_id: iso_doc.id,
                                       filename: docuvita_filename,
                                       response: upload_result[:response] })
              error_count += 1
            end
          end

        rescue StandardError => e
          puts "  [ERROR] Exception during upload for Isometry ##{isometry.id}: #{e.message}"
          ProjectLog.error("Docuvita upload exception", source: "RakeTask",
                          metadata: { project_id: project.id,
                                    isometry_id: isometry.id,
                                    isometry_document_id: iso_doc&.id,
                                    filename: docuvita_filename,
                                    error: e.message,
                                    backtrace: e.backtrace.first(5).join("\n") })
          error_count += 1
        end
      end
      puts "Finished processing batch."
      break if limit_reached
    end

    puts "\n--------------------------------------------------"
    puts "Task finished. Limit: #{effective_limit}, Attempts: #{upload_attempts}, Uploaded: #{uploaded_count}, Skipped: #{skipped_count}, Errors: #{error_count}."
  end
end
