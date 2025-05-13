# lib/tasks/on_site_docuvita_upload.rake
namespace :docuvita do
  desc "Upload OnSite images to Docuvita. Usage: rails docuvita:upload_on_site_images [count] [project_id] [type]"
  task :upload_on_site_images, [ :count, :project_id, :type ] => :environment do |_task, args|
    # Get the number of images to upload from args or prompt for it
    upload_count = if args[:count].present?
                     args[:count].to_i
    else
                     print "Enter the number of on-site images to upload (default: 10): "
                     input = STDIN.gets.chomp
                     input.present? ? input.to_i : 10
    end

    # Get the project ID if provided
    project_id = args[:project_id]

    # Get the image type if provided (on_hold_images or images)
    image_type = args[:type].present? ? args[:type] : nil

    unless image_type.nil? || [ "on_hold_images", "images" ].include?(image_type)
      puts "Error: Invalid image type. Must be 'on_hold_images' or 'images'."
      exit 1
    end

    image_type_display = image_type.nil? ? "all types" : image_type

    if project_id.present?
      project = Project.find_by(id: project_id)
      if project.nil?
        puts "Error: Project with ID #{project_id} not found."
        exit 1
      end
      puts "Starting Docuvita OnSite #{image_type_display} upload for Project: #{project.project_number} (Count: #{upload_count})..."
    else
      puts "Starting Docuvita OnSite #{image_type_display} upload for ALL projects (Count: #{upload_count})..."
    end
    puts "--------------------------------------------------"

    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    total_processed = 0

    # First, check if there are any OnSite records with images
    total_on_sites = OnSite.count
    puts "Total OnSite records in database: #{total_on_sites}"

    # Check how many have attached images using ActiveStorage directly
    if image_type.nil? || image_type == "on_hold_images"
      on_hold_attachments_count = ActiveStorage::Attachment.where(record_type: "OnSite", name: "on_hold_images").count
      puts "Total OnSite records with on_hold_images attached: #{on_hold_attachments_count}"
    end

    if image_type.nil? || image_type == "images"
      images_attachments_count = ActiveStorage::Attachment.where(record_type: "OnSite", name: "images").count
      puts "Total OnSite records with images attached: #{images_attachments_count}"
    end

    if (image_type.nil? && on_hold_attachments_count == 0 && images_attachments_count == 0) ||
       (image_type == "on_hold_images" && on_hold_attachments_count == 0) ||
       (image_type == "images" && images_attachments_count == 0)
      puts "No OnSite records found with the requested attached images. Nothing to migrate."
      exit 0
    end

    # Base query - get on_sites that have the requested images attached
    base_query = OnSite.includes(:docuvita_documents, :project)

    if image_type.nil?
      # For both types, use a more complex query
      base_query = base_query.joins("LEFT JOIN active_storage_attachments AS att1 ON att1.record_id = on_sites.id AND att1.record_type = 'OnSite' AND att1.name = 'on_hold_images'")
                            .joins("LEFT JOIN active_storage_attachments AS att2 ON att2.record_id = on_sites.id AND att2.record_type = 'OnSite' AND att2.name = 'images'")
                            .where("att1.id IS NOT NULL OR att2.id IS NOT NULL")
    elsif image_type == "on_hold_images"
      base_query = base_query.joins("INNER JOIN active_storage_attachments ON active_storage_attachments.record_id = on_sites.id AND active_storage_attachments.record_type = 'OnSite' AND active_storage_attachments.name = 'on_hold_images'")
    else # images
      base_query = base_query.joins("INNER JOIN active_storage_attachments ON active_storage_attachments.record_id = on_sites.id AND active_storage_attachments.record_type = 'OnSite' AND active_storage_attachments.name = 'images'")
    end

    base_query = base_query.distinct

    # Filter by project if specified
    base_query = base_query.where(project_id: project_id) if project_id.present?

    puts "Found #{base_query.count} OnSite records with the requested images to process"

    base_query.find_in_batches(batch_size: 20) do |batch|
      puts "Processing batch of #{batch.size} on-sites..."

      batch.each do |on_site|
        break if uploaded_count >= upload_count

        puts "\nProcessing OnSite ##{on_site.id} (Project: #{on_site.project.project_number})..."

        # Process on_hold_images if requested
        if image_type.nil? || image_type == "on_hold_images"
          # Check if already has Docuvita documents for on_hold_images
          existing_on_hold_docs = on_site.docuvita_documents.where(document_sub_type: "on_hold_image")

          if existing_on_hold_docs.exists?
            puts "  [SKIP] Already has #{existing_on_hold_docs.count} on_hold_images in Docuvita."
            skipped_count += 1
          elsif !on_site.on_hold_images.attached?
            puts "  [SKIP] No on_hold_images attached."
            skipped_count += 1
          else
            # Process each attached on_hold_image
            on_site.on_hold_images.each_with_index do |image, index|
              break if uploaded_count >= upload_count

              begin
                # Get the attached file and prepare for upload
                image_blob = image.blob
                original_filename = image_blob.filename.to_s

                puts "  Uploading on_hold_image #{index + 1}/#{on_site.on_hold_images.count}: '#{original_filename}' (OnSite ##{on_site.id})..."

                # Process the file using ActiveStorage's open method
                image.open do |tempfile|
                  # Create a temporary file that mimics an uploaded file
                  uploaded_file = ActionDispatch::Http::UploadedFile.new(
                    tempfile: tempfile,
                    filename: original_filename,
                    type: image_blob.content_type
                  )

                  # Use the model's upload method from DocuvitaUploadable concern
                  on_site.upload_image_to_docuvita(uploaded_file, original_filename, "on_hold_image", "as_built")

                  # After upload, find the newly created document
                  new_doc = on_site.docuvita_documents.where(document_sub_type: "on_hold_image").order(created_at: :desc).first

                  if new_doc
                    puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
                    ProjectLog.info("Docuvita upload success via rake task",
                                  source: "RakeTask",
                                  metadata: {
                                    on_site_id: on_site.id,
                                    docuvita_object_id: new_doc.docuvita_object_id,
                                    filename: original_filename,
                                    image_type: "on_hold_image"
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
                puts "  [ERROR] Exception during upload for OnSite ##{on_site.id}, on_hold_image '#{original_filename}': #{e.message}"
                ProjectLog.error("Docuvita upload exception",
                               source: "RakeTask",
                               metadata: {
                                 on_site_id: on_site.id,
                                 filename: original_filename,
                                 image_type: "on_hold_image",
                                 error: e.message,
                                 backtrace: e.backtrace.first(5).join("\n")
                               })
                error_count += 1
              end
            end
          end
        end

        # Process regular images if requested and we haven't reached the upload count
        if (image_type.nil? || image_type == "images") && uploaded_count < upload_count
          # Check if already has Docuvita documents for on_site_images
          existing_on_site_docs = on_site.docuvita_documents.where(document_sub_type: "on_site_image")

          if existing_on_site_docs.exists?
            puts "  [SKIP] Already has #{existing_on_site_docs.count} on_site_images in Docuvita."
            skipped_count += 1
          elsif !on_site.images.attached?
            puts "  [SKIP] No images attached."
            skipped_count += 1
          else
            # Process each attached image
            on_site.images.each_with_index do |image, index|
              break if uploaded_count >= upload_count

              begin
                # Get the attached file and prepare for upload
                image_blob = image.blob
                original_filename = image_blob.filename.to_s

                puts "  Uploading on_site_image #{index + 1}/#{on_site.images.count}: '#{original_filename}' (OnSite ##{on_site.id})..."

                # Process the file using ActiveStorage's open method
                image.open do |tempfile|
                  # Create a temporary file that mimics an uploaded file
                  uploaded_file = ActionDispatch::Http::UploadedFile.new(
                    tempfile: tempfile,
                    filename: original_filename,
                    type: image_blob.content_type
                  )

                  # Use the model's upload method from DocuvitaUploadable concern
                  on_site.upload_image_to_docuvita(uploaded_file, original_filename, "on_site_image", "as_built")

                  # After upload, find the newly created document
                  new_doc = on_site.docuvita_documents.where(document_sub_type: "on_site_image").order(created_at: :desc).first

                  if new_doc
                    puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
                    ProjectLog.info("Docuvita upload success via rake task",
                                  source: "RakeTask",
                                  metadata: {
                                    on_site_id: on_site.id,
                                    docuvita_object_id: new_doc.docuvita_object_id,
                                    filename: original_filename,
                                    image_type: "on_site_image"
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
                puts "  [ERROR] Exception during upload for OnSite ##{on_site.id}, on_site_image '#{original_filename}': #{e.message}"
                ProjectLog.error("Docuvita upload exception",
                               source: "RakeTask",
                               metadata: {
                                 on_site_id: on_site.id,
                                 filename: original_filename,
                                 image_type: "on_site_image",
                                 error: e.message,
                                 backtrace: e.backtrace.first(5).join("\n")
                               })
                error_count += 1
              end
            end
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
