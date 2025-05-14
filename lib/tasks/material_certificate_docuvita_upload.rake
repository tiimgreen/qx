# lib/tasks/material_certificate_docuvita_upload.rake
namespace :docuvita do
  desc "Upload Material Certificate files to Docuvita with latest implementation. Usage: rails docuvita:upload_material_certificates_v2 [count]"
  task :upload_material_certificates_v2, [ :count ] => :environment do |_task, args|
    # Get the number of certificates to upload from args or prompt for it
    upload_count = if args[:count].present?
                     args[:count].to_i
    else
                     print "Enter the number of certificates to upload (default: 10): "
                     input = STDIN.gets.chomp
                     input.present? ? input.to_i : 10
    end

    puts "Starting Docuvita Material Certificate upload (Count: #{upload_count})..."
    puts "--------------------------------------------------"

    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    total_processed = 0

    # Get certificates that have a file attached but no Docuvita document
    MaterialCertificate.includes(:docuvita_documents)
                      .joins("LEFT JOIN active_storage_attachments ON active_storage_attachments.record_id = material_certificates.id AND active_storage_attachments.record_type = 'MaterialCertificate' AND active_storage_attachments.name = 'certificate_file'")
                      .where("active_storage_attachments.id IS NOT NULL")
                      .find_in_batches(batch_size: 50) do |batch|
      puts "Processing batch of #{batch.size} certificates..."

      batch.each do |certificate|
        break if uploaded_count >= upload_count

        puts "\nProcessing Material Certificate ##{certificate.id} (Number: #{certificate.certificate_number || 'N/A'})..."

        # Skip if no certificate number (required for Docuvita metadata)
        unless certificate.certificate_number.present?
          puts "  [SKIP] Certificate Number is missing, which is required for Docuvita metadata."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Check if already uploaded to Docuvita - using the correct document_type
        existing_docuvita_docs = certificate.docuvita_documents.where(document_sub_type: "material_certificate").or(
          certificate.docuvita_documents.where(document_sub_type: "material_certificate")
        )

        if existing_docuvita_docs.exists?
          puts "  [SKIP] Already uploaded. Docuvita Object ID: #{existing_docuvita_docs.first.docuvita_object_id}"
          skipped_count += 1
          total_processed += 1
          next
        end

        # Check for attached file
        unless certificate.respond_to?(:certificate_file) && certificate.certificate_file.attached?
          puts "  [SKIP] No certificate file attached."
          skipped_count += 1
          total_processed += 1
          next
        end

        begin
          # Get the attached file and prepare for upload
          certificate_blob = certificate.certificate_file.blob
          original_filename = certificate_blob.filename.to_s

          puts "  Uploading '#{original_filename}' (Certificate ##{certificate.id})..."

          # Process the file using ActiveStorage's open method
          certificate.certificate_file.open do |tempfile|
            # Create a temporary file that mimics an uploaded file
            uploaded_file = ActionDispatch::Http::UploadedFile.new(
              tempfile: tempfile,
              filename: original_filename,
              type: certificate_blob.content_type
            )

            # Use the model's upload method from DocuvitaUploadable concern
            # The upload_certificate_to_docuvita method doesn't return the DocuvitaDocument
            # So we need to call it and then check if a document was created
            certificate.upload_certificate_to_docuvita(uploaded_file, original_filename)

            # After upload, find the newly created document
            new_doc = certificate.docuvita_documents.where(document_sub_type: "material_certificate").order(created_at: :desc).first

            if new_doc
              puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
              ProjectLog.info("Docuvita upload success via rake task",
                            source: "RakeTask",
                            metadata: {
                              material_certificate_id: certificate.id,
                              docuvita_object_id: new_doc.docuvita_object_id,
                              filename: original_filename
                            })

              uploaded_count += 1
            else
              puts "  [WARNING] Upload may have succeeded but no DocuvitaDocument record was found."
              error_count += 1
            end
            total_processed += 1
          end
        rescue StandardError => e
          puts "  [ERROR] Exception during upload for Certificate ##{certificate.id}: #{e.message}"
          ProjectLog.error("Docuvita upload exception",
                         source: "RakeTask",
                         metadata: {
                           material_certificate_id: certificate.id,
                           filename: original_filename,
                           error: e.message,
                           backtrace: e.backtrace.first(5).join("\n")
                         })
          error_count += 1
          total_processed += 1
        end
      end

      # Break out of the batch processing if we've reached our upload count
      break if uploaded_count >= upload_count
    end

    puts "\n--------------------------------------------------"
    puts "Task finished. Requested: #{upload_count}, Processed: #{total_processed}, Uploaded: #{uploaded_count}, Skipped: #{skipped_count}, Errors: #{error_count}."
  end
end
