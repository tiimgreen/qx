# lib/tasks/incoming_delivery_notes_script.rake
require "pathname"

namespace :docuvita do
  desc "Upload existing IncomingDelivery delivery_notes from ActiveStorage to Docuvita. Usage: rails docuvita:upload_delivery_notes [limit]"
  task :upload_delivery_notes, [ :limit ] => :environment do |_task, args|
    # Set a default limit or use the one from args, default to a high number if none provided
    upload_limit = args[:limit].present? ? args[:limit].to_i : 1_000_000 # Effectively no limit unless specified
    testing_limit = 5 # Define the specific limit for testing
    effective_limit = [ upload_limit, testing_limit ].min # Use the smaller of the argument or the hardcoded test limit

    puts "Starting Docuvita Delivery Notes upload (Limit: #{effective_limit})..."
    puts "--------------------------------------------------"

    # Initialize uploader with the correct object type ID for delivery notes
    uploader = DocuvitaUploader.new(object_type_id: 29) # Use the same object type ID as in README example
    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    upload_attempts = 0 # Counter for attempts
    limit_reached = false # Flag to break outer loop

    # Find IncomingDeliveries that have delivery_notes attached
    # Query ActiveStorage::Attachment directly and eager load associations
    attachments_query = ActiveStorage::Attachment.where(
      record_type: "IncomingDelivery",
      name: "delivery_notes"
    ).includes(:record, :blob)

    total_eligible_attachments = attachments_query.count
    puts "Found #{total_eligible_attachments} potential delivery note attachments to process."

    attachments_query.find_in_batches(batch_size: 100) do |attachment_batch|
      puts "Processing batch of #{attachment_batch.size} attachments..."
      attachment_batch.each do |attachment|
        break if limit_reached # Stop processing this batch if limit was hit

        delivery = attachment.record
        blob = attachment.blob
        original_filename = blob.filename.to_s

        puts "\nProcessing Attachment ##{attachment.id} for IncomingDelivery ##{delivery&.id || 'N/A'} (Filename: #{original_filename})... (Attempt ##{upload_attempts + 1})"

        # --- Basic Checks ---
        unless delivery
          puts "  [SKIP] IncomingDelivery record not found for Attachment ##{attachment.id}."
          ProjectLog.warn("Orphaned delivery note attachment found", source: "RakeTask", metadata: { attachment_id: attachment.id })
          skipped_count += 1
          next
        end

        # --- Check if Already Uploaded ---
        local_document_type = "delivery_note_pdf"
        existing_docuvita_doc = delivery.docuvita_documents.of_type(local_document_type).where(filename: original_filename).first
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
        upload_attempts += 1 # Increment only for eligible attachments that will be attempted

        # --- Prepare Metadata ---
        delivery_metadata = {
          delivery_note_number: delivery.delivery_note_number,
          order_number: delivery.order_number,
          supplier_name: delivery.supplier_name,
          project_id: delivery.project_id,
          original_filename: original_filename
        }

        # --- Docuvita API Payload Preparation ---
        docuvita_filename = "#{delivery.delivery_note_number}_dn.pdf"
        api_description = delivery_metadata
        voucher_number = delivery.delivery_note_number
        transaction_key = delivery.project&.project_number || "UNKNOWN_PROJECT"
        local_document_type = "delivery_note_pdf" # Type for our DocuvitaDocument model
        docuvita_api_document_type = "DeliveryNote" # Type for Docuvita API

        unless delivery.delivery_note_number.present?
          puts "  [SKIP] Delivery Note Number is missing, which is required for Docuvita metadata (voucher_number)."
          skipped_count += 1
          upload_attempts -= 1 # Decrement since we didn't really attempt
          next
        end

        puts "  Uploading '#{original_filename}' (Delivery ##{delivery.id}) as '#{docuvita_filename}'..."

        begin
          # --- Perform Upload ---
          blob.open do |tempfile|
            upload_result = uploader.upload_file(
              tempfile.path,
              {
                name: docuvita_filename,
                description: api_description,
                voucher_number: voucher_number,
                transaction_key: transaction_key,
                document_type: docuvita_api_document_type,
                version_original_filename: original_filename
              }
            )
            object_id = upload_result[:object_id]

            # --- Create DocuvitaDocument record ---
            if object_id
              DocuvitaDocument.create!(
                documentable: delivery,
                docuvita_object_id: object_id,
                document_type: local_document_type,
                metadata: delivery_metadata,
                filename: docuvita_filename,
                content_type: blob.content_type,
                byte_size: blob.byte_size,
                checksum: blob.checksum
              )
              puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{object_id}."
              ProjectLog.info("Docuvita upload success", source: "RakeTask",
                            metadata: { project_id: delivery.project_id,
                                      incoming_delivery_id: delivery.id,
                                      docuvita_object_id: object_id,
                                      filename: docuvita_filename })
              uploaded_count += 1
            else
              error_message = upload_result.dig(:response, "Error") || upload_result[:response].to_s
              puts "  [FAIL] Upload failed. Response: #{error_message}"
              ProjectLog.error("Docuvita upload failed", source: "RakeTask",
                             metadata: { project_id: delivery.project_id,
                                       incoming_delivery_id: delivery.id,
                                       filename: docuvita_filename,
                                       response: upload_result[:response] })
              error_count += 1
            end
          end # blob.open
        rescue StandardError => e
          puts "  [ERROR] Exception during upload for Delivery ##{delivery.id}: #{e.message}"
          ProjectLog.error("Docuvita upload exception", source: "RakeTask",
                          metadata: { project_id: delivery.project_id,
                                    incoming_delivery_id: delivery.id,
                                    filename: docuvita_filename,
                                    error: e.message,
                                    backtrace: e.backtrace.first(5).join("\n") })
          error_count += 1
        end
      end # attachment_batch.each
      puts "Finished processing batch."
      break if limit_reached # Exit outer find_in_batches loop if limit was reached
    end # find_in_batches

    puts "\n--------------------------------------------------"
    puts "Task finished. Limit: #{effective_limit}, Attempts: #{upload_attempts}, Uploaded: #{uploaded_count}, Skipped: #{skipped_count}, Errors: #{error_count}."
  end
end
