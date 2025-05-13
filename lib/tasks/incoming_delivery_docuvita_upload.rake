# lib/tasks/incoming_delivery_docuvita_upload.rake
namespace :docuvita do
  desc "Upload IncomingDelivery attachments to Docuvita with latest implementation. Usage: rails docuvita:upload_incoming_delivery_attachments [count]"
  task :upload_incoming_delivery_attachments, [ :count ] => :environment do |_task, args|
    # Get the number of deliveries to process from args or prompt for it
    upload_count = if args[:count].present?
                     args[:count].to_i
    else
                     print "Enter the number of deliveries to process (default: 10): "
                     input = STDIN.gets.chomp
                     input.present? ? input.to_i : 100
    end

    puts "Starting Docuvita IncomingDelivery attachments upload (Count: #{upload_count})..."
    puts "--------------------------------------------------"

    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    total_processed = 0

    # Ask user which type of attachments to upload
    print "Upload delivery notes? (Y/n): "
    upload_delivery_notes = (STDIN.gets.chomp.downcase != "n")

    print "Upload on-hold images? (Y/n): "
    upload_on_hold_images = (STDIN.gets.chomp.downcase != "n")

    unless upload_delivery_notes || upload_on_hold_images
      puts "No attachment types selected for upload. Exiting."
      return
    end

    puts "Will upload: #{upload_delivery_notes ? 'Delivery Notes' : ''} #{upload_on_hold_images ? 'On-Hold Images' : ''}"

    # Find IncomingDeliveries with attachments
    if upload_delivery_notes
      process_delivery_notes(upload_count, uploaded_count, skipped_count, error_count, total_processed)
    end

    if upload_on_hold_images
      process_on_hold_images(upload_count, uploaded_count, skipped_count, error_count, total_processed)
    end

    puts "\n--------------------------------------------------"
    puts "Task finished. Requested: #{upload_count}, Processed: #{total_processed}, Uploaded: #{uploaded_count}, Skipped: #{skipped_count}, Errors: #{error_count}."
  end

  private

  def process_delivery_notes(upload_count, uploaded_count, skipped_count, error_count, total_processed)
    puts "\nProcessing Delivery Notes..."

    # Find attachments directly from ActiveStorage
    attachments_query = ActiveStorage::Attachment.where(
      record_type: "IncomingDelivery",
      name: "delivery_notes"
    ).includes(:record, :blob)

    total_eligible_attachments = attachments_query.count
    puts "Found #{total_eligible_attachments} potential delivery note attachments to process."

    attachments_query.find_in_batches(batch_size: 50) do |attachment_batch|
      puts "Processing batch of #{attachment_batch.size} attachments..."

      attachment_batch.each do |attachment|
        break if uploaded_count >= upload_count

        delivery = attachment.record
        blob = attachment.blob
        original_filename = blob.filename.to_s

        puts "\nProcessing Delivery Note: #{original_filename} for IncomingDelivery ##{delivery&.id || 'N/A'}..."

        # Skip if delivery record not found
        unless delivery
          puts "  [SKIP] IncomingDelivery record not found for Attachment ##{attachment.id}."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Skip if delivery note number is missing
        unless delivery.delivery_note_number.present?
          puts "  [SKIP] Delivery Note Number is missing, which is required for Docuvita metadata."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Check if already uploaded to Docuvita
        existing_docuvita_docs = delivery.docuvita_documents.where(document_sub_type: "delivery_note")
        if existing_docuvita_docs.exists?
          puts "  [SKIP] Already uploaded. Docuvita Object ID: #{existing_docuvita_docs.first.docuvita_object_id}"
          skipped_count += 1
          total_processed += 1
          next
        end

        begin
          blob.open do |tempfile|
            # Check if this is an image file
            is_image = blob.content_type&.start_with?("image/") ||
                      %w[.jpg .jpeg .png .gif .bmp .tiff].include?(File.extname(original_filename).downcase)

            # Create a temporary file that mimics an uploaded file
            uploaded_file = ActionDispatch::Http::UploadedFile.new(
              tempfile: tempfile,
              filename: original_filename,
              type: blob.content_type
            )

            if is_image
              puts "  Uploading image as PDF: '#{original_filename}'"
              # Use the model's upload_image_to_docuvita method
              delivery.upload_image_to_docuvita(
                uploaded_file,
                original_filename,
                "delivery_note",
                "incoming_delivery"
              )
            else
              puts "  Uploading document: '#{original_filename}'"
              # Use the model's upload_pdf_to_docuvita method
              delivery.upload_pdf_to_docuvita(
                uploaded_file,
                original_filename,
                "incoming_delivery",
                {
                  voucher_number: delivery.delivery_note_number,
                  transaction_key: delivery.project&.project_number || "",
                  document_type: "IncomingDelivery",
                  voucher_type: "delivery_note",
                  description: {
                    delivery_note_number: delivery.delivery_note_number,
                    order_number: delivery.order_number,
                    supplier_name: delivery.supplier_name,
                    project_id: delivery.project_id,
                    original_filename: original_filename,
                    upload_context: "rake_task"
                  }
                }
              )
            end

            # After upload, find the newly created document
            new_doc = delivery.docuvita_documents.where(document_sub_type: "delivery_note").order(created_at: :desc).first

            if new_doc
              puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
              ProjectLog.info("Docuvita upload success via rake task",
                            source: "RakeTask",
                            metadata: {
                              project_id: delivery.project_id,
                              incoming_delivery_id: delivery.id,
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
          puts "  [ERROR] Exception during upload for Delivery ##{delivery.id}: #{e.message}"
          ProjectLog.error("Docuvita upload exception",
                         source: "RakeTask",
                         metadata: {
                           project_id: delivery.project_id,
                           incoming_delivery_id: delivery.id,
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

    return uploaded_count, skipped_count, error_count, total_processed
  end

  def process_on_hold_images(upload_count, uploaded_count, skipped_count, error_count, total_processed)
    puts "\nProcessing On-Hold Images..."

    # Find attachments directly from ActiveStorage
    attachments_query = ActiveStorage::Attachment.where(
      record_type: "IncomingDelivery",
      name: "on_hold_images"
    ).includes(:record, :blob)

    total_eligible_attachments = attachments_query.count
    puts "Found #{total_eligible_attachments} potential on-hold image attachments to process."

    attachments_query.find_in_batches(batch_size: 50) do |attachment_batch|
      puts "Processing batch of #{attachment_batch.size} attachments..."

      attachment_batch.each do |attachment|
        break if uploaded_count >= upload_count

        delivery = attachment.record
        blob = attachment.blob
        original_filename = blob.filename.to_s

        puts "\nProcessing On-Hold Image: #{original_filename} for IncomingDelivery ##{delivery&.id || 'N/A'}..."

        # Skip if delivery record not found
        unless delivery
          puts "  [SKIP] IncomingDelivery record not found for Attachment ##{attachment.id}."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Check if already uploaded to Docuvita
        existing_docuvita_docs = delivery.docuvita_documents.where(document_sub_type: "on_hold_image")
        if existing_docuvita_docs.exists?
          puts "  [SKIP] Already uploaded. Docuvita Object ID: #{existing_docuvita_docs.first.docuvita_object_id}"
          skipped_count += 1
          total_processed += 1
          next
        end

        begin
          blob.open do |tempfile|
            # Create a temporary file that mimics an uploaded file
            uploaded_file = ActionDispatch::Http::UploadedFile.new(
              tempfile: tempfile,
              filename: original_filename,
              type: blob.content_type
            )

            puts "  Uploading on-hold image: '#{original_filename}'"
            # Use the model's upload_image_to_docuvita method
            delivery.upload_image_to_docuvita(
              uploaded_file,
              original_filename,
              "on_hold_image",
              "incoming_delivery"
            )

            # After upload, find the newly created document
            new_doc = delivery.docuvita_documents.where(document_sub_type: "on_hold_image").order(created_at: :desc).first

            if new_doc
              puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
              ProjectLog.info("Docuvita upload success via rake task",
                            source: "RakeTask",
                            metadata: {
                              project_id: delivery.project_id,
                              incoming_delivery_id: delivery.id,
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
          puts "  [ERROR] Exception during upload for Delivery ##{delivery.id}: #{e.message}"
          ProjectLog.error("Docuvita upload exception",
                         source: "RakeTask",
                         metadata: {
                           project_id: delivery.project_id,
                           incoming_delivery_id: delivery.id,
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

    return uploaded_count, skipped_count, error_count, total_processed
  end
end
