# lib/tasks/transport_docuvita_upload.rake
namespace :docuvita do
  desc "Upload Transport check_spools_images to Docuvita. Usage: rails docuvita:upload_transport_images [count] [project_id]"
  task :upload_transport_images, [ :count, :project_id ] => :environment do |_task, args|
    # Get the number of images to upload from args or prompt for it
    upload_count = if args[:count].present?
                     args[:count].to_i
    else
                     print "Enter the number of transport images to upload (default: 10): "
                     input = STDIN.gets.chomp
                     input.present? ? input.to_i : 10
    end

    # Get the project ID if provided
    project_id = args[:project_id]

    if project_id.present?
      project = Project.find_by(id: project_id)
      if project.nil?
        puts "Error: Project with ID #{project_id} not found."
        exit 1
      end
      puts "Starting Docuvita Transport check_spools_images upload for Project: #{project.project_number} (Count: #{upload_count})..."
    else
      puts "Starting Docuvita Transport check_spools_images upload for ALL projects (Count: #{upload_count})..."
    end
    puts "--------------------------------------------------"

    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    total_processed = 0

    # First, check if there are any Transport records with check_spools_images
    total_transports = Transport.count
    puts "Total Transport records in database: #{total_transports}"

    # Check how many have attached images using ActiveStorage directly
    attachments_count = ActiveStorage::Attachment.where(record_type: "Transport", name: "check_spools_images").count
    puts "Total Transport records with check_spools_images attached: #{attachments_count}"

    if attachments_count == 0
      puts "No Transport records found with attached check_spools_images. Nothing to migrate."
      exit 0
    end

    # Base query - get transports that have check_spools_images attached
    base_query = Transport.includes(:docuvita_documents, :project)
                               .joins("INNER JOIN active_storage_attachments ON active_storage_attachments.record_id = transports.id AND active_storage_attachments.record_type = 'Transport' AND active_storage_attachments.name = 'check_spools_images'")
                               .distinct

    # Filter by project if specified
    base_query = base_query.where(project_id: project_id) if project_id.present?

    puts "Found #{base_query.count} Transport records with check_spools_images to process"

    base_query.find_in_batches(batch_size: 20) do |batch|
      puts "Processing batch of #{batch.size} transports..."

      batch.each do |transport|
        break if uploaded_count >= upload_count

        puts "\nProcessing Transport ##{transport.id} (Project: #{transport.project.project_number})..."

        # Check if already has Docuvita documents for check_spools_images
        existing_docuvita_docs = transport.docuvita_documents.where(document_sub_type: "check_spools_image")

        if existing_docuvita_docs.exists?
          puts "  [SKIP] Already has #{existing_docuvita_docs.count} check_spools_images in Docuvita."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Check for attached check_spools_images
        unless transport.check_spools_images.attached?
          puts "  [SKIP] No check_spools_images attached."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Process each attached image
        transport.check_spools_images.each_with_index do |image, index|
          begin
            # Get the attached file and prepare for upload
            image_blob = image.blob
            original_filename = image_blob.filename.to_s

            puts "  Uploading image #{index + 1}/#{transport.check_spools_images.count}: '#{original_filename}' (Transport ##{transport.id})..."

            # Process the file using ActiveStorage's open method
            image.open do |tempfile|
              # Create a temporary file that mimics an uploaded file
              uploaded_file = ActionDispatch::Http::UploadedFile.new(
                tempfile: tempfile,
                filename: original_filename,
                type: image_blob.content_type
              )

              # Use the model's upload method from DocuvitaUploadable concern
              transport.upload_image_to_docuvita(uploaded_file, original_filename, "check_spools_image", "transport")

              # After upload, find the newly created document
              new_doc = transport.docuvita_documents.where(document_sub_type: "check_spools_image").order(created_at: :desc).first

              if new_doc
                puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
                ProjectLog.info("Docuvita upload success via rake task",
                              source: "RakeTask",
                              metadata: {
                                transport_id: transport.id,
                                docuvita_object_id: new_doc.docuvita_object_id,
                                filename: original_filename
                              })

                uploaded_count += 1
                # Break if we've reached our upload count
                break if uploaded_count >= upload_count
              else
                puts "  [WARNING] Upload may have succeeded but no DocuvitaDocument record was found."
                error_count += 1
              end
            end
          rescue StandardError => e
            puts "  [ERROR] Exception during upload for Transport ##{transport.id}, image '#{original_filename}': #{e.message}"
            ProjectLog.error("Docuvita upload exception",
                           source: "RakeTask",
                           metadata: {
                             transport_id: transport.id,
                             filename: original_filename,
                             error: e.message,
                             backtrace: e.backtrace.first(5).join("\n")
                           })
            error_count += 1
          end
        end

        total_processed += 1
      end

      # Break out of the batch processing if we've reached our upload count
      break if uploaded_count >= upload_count
    end

    puts "\n--------------------------------------------------"
    puts "Task finished. Requested: #{upload_count}, Processed: #{total_processed}, Uploaded: #{uploaded_count}, Skipped: #{skipped_count}, Errors: #{error_count}."
  end
end
