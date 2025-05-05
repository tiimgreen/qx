# lib/tasks/material_certificate_upload.rake
require "pathname"

namespace :docuvita do
  desc "Upload Material Certificate files to Docuvita. Usage: rails docuvita:upload_material_certificates [limit]"
  task :upload_material_certificates, [ :limit ] => :environment do |_task, args|
    # Set a default limit or use the one from args, default to a high number if none provided
    upload_limit = args[:limit].present? ? args[:limit].to_i : 1_000_000 # Effectively no limit unless specified
    testing_limit = 10 # Define the specific limit for testing
    effective_limit = [ upload_limit, testing_limit ].min # Use the smaller of the argument or the hardcoded test limit

    puts "Starting Docuvita Material Certificate upload (Limit: #{effective_limit})..."
    puts "--------------------------------------------------"

    uploader = DocuvitaUploader.new
    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    upload_attempts = 0 # Counter for attempts
    limit_reached = false # Flag to break outer loop

    # Eager load attachments and existing docuvita documents to minimize queries
    # Process in batches of 100
    MaterialCertificate.includes(:certificate_file_attachment, :docuvita_documents, { isometries: :project })
                       .find_in_batches(batch_size: 100) do |certificates_batch|
      puts "Processing batch of #{certificates_batch.size} certificates..."
      certificates_batch.each do |certificate| # Iterate through the certificates in the current batch
        break if limit_reached # Stop processing this batch if limit was hit

        puts "\nProcessing Material Certificate ##{certificate.id} (Number: #{certificate.certificate_number || 'N/A'})... (Attempt ##{upload_attempts + 1})"

        # 1. Check for attached file
        unless certificate.certificate_file.attached?
          puts "  [SKIP] No certificate file attached."
          skipped_count += 1
          next
        end
        certificate_blob = certificate.certificate_file.blob
        original_filename = certificate_blob.filename.to_s

        # 2. Check if already uploaded to Docuvita for this certificate
        local_document_type = "material_certificate_pdf"
        existing_docuvita_doc = certificate.docuvita_documents.of_type(local_document_type).first
        if existing_docuvita_doc
          puts "  [SKIP] Already uploaded. Docuvita Object ID: #{existing_docuvita_doc.docuvita_object_id}"
          skipped_count += 1
          next
        end

        # --- Check and Increment Attempt Counter ---
        if upload_attempts >= effective_limit
          puts "  [INFO] Reached upload limit of #{effective_limit}. Stopping."
          limit_reached = true
          break # Exit inner .each loop
        end
        upload_attempts += 1 # Increment only for eligible certificates that will be attempted

        # 3. Prepare metadata...
        # ... (rest of the metadata preparation code remains the same) ...
        project = certificate.isometries.first&.project
        project_number = project&.project_number || "N/A"

        unless certificate.certificate_number.present?
           puts "  [SKIP] Certificate Number is missing, which is required for Docuvita metadata (voucher_number)."
           skipped_count += 1
           upload_attempts -= 1 # Decrement since we didn't really attempt
           next
        end

        docuvita_filename = "#{certificate.certificate_number}_cert.pdf"
        description = "Material Certificate: #{certificate.certificate_number}, Batch: #{certificate.batch_number || 'N/A'}, Project: #{project_number}. Original: #{original_filename}"
        voucher_number = certificate.certificate_number
        transaction_key = project_number
        docuvita_api_document_type = "MaterialCertificate"

        puts "  Uploading '#{original_filename}' as '#{docuvita_filename}'..."

        begin
          # 4. Perform upload...
          # ... (upload logic remains the same) ...
          certificate.certificate_file.open do |tempfile|
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
            # 5. Create DocuvitaDocument record...
            # ... (record creation logic remains the same) ...
            if object_id
               # ... create record ...
               DocuvitaDocument.create!(
                 documentable: certificate,
                 docuvita_object_id: object_id,
                 document_type: local_document_type, # Use the specific local type
                 filename: docuvita_filename,
                 content_type: certificate_blob.content_type,
                 byte_size: certificate_blob.byte_size,
                 checksum: certificate_blob.checksum
               )
              puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{object_id}."
              ProjectLog.info("Docuvita upload success", source: "RakeTask", metadata: { project_id: project&.id, material_certificate_id: certificate.id, docuvita_object_id: object_id, filename: docuvita_filename })
              uploaded_count += 1
            else
              # ... handle failure ...
              error_message = upload_result.dig(:response, "Error") || upload_result[:response].to_s
              puts "  [FAIL] Upload failed. Response: #{error_message}"
              ProjectLog.error("Docuvita upload failed", source: "RakeTask", metadata: { project_id: project&.id, material_certificate_id: certificate.id, filename: docuvita_filename, response: upload_result[:response] })
              error_count += 1
            end
          end # ActiveStorage#open
        rescue StandardError => e
           # ... (exception handling remains the same) ...
           puts "  [ERROR] Exception during upload for Certificate ##{certificate.id}: #{e.message}"
           ProjectLog.error("Docuvita upload exception", source: "RakeTask", metadata: { project_id: project&.id, material_certificate_id: certificate.id, filename: docuvita_filename, error: e.message, backtrace: e.backtrace.first(5).join("\n") })
           error_count += 1
        end
      end # certificates_batch.each
      puts "Finished processing batch."
      break if limit_reached # Exit outer find_in_batches loop if limit was reached
    end # find_in_batches

    puts "\n--------------------------------------------------"
    puts "Task finished. Limit: #{effective_limit}, Attempts: #{upload_attempts}, Uploaded: #{uploaded_count}, Skipped: #{skipped_count}, Errors: #{error_count}."
  end
end
