# lib/tasks/delivery_item_docuvita_upload.rake
namespace :docuvita do
  desc "Upload DeliveryItem images to Docuvita. Usage: rails docuvita:upload_delivery_item_images [count] [project_id] [image_type]"
  task :upload_delivery_item_images, [ :count, :project_id, :image_type ] => :environment do |_task, args|
    # Get the number of images to upload from args or prompt for it
    upload_count = if args[:count].present?
                     args[:count].to_i
    else
                     print "Enter the number of delivery item images to upload (default: 10): "
                     input = STDIN.gets.chomp
                     input.present? ? input.to_i : 10
    end

    # Get the project ID if provided
    project_id = args[:project_id]

    # Get the image type if provided
    image_type = args[:image_type]

    # Valid image types
    valid_image_types = [
      "quantity_check_images",
      "dimension_check_images",
      "visual_check_images",
      "vt2_check_images",
      "ra_check_images",
      "on_hold_images"
    ]

    unless image_type.nil? || valid_image_types.include?(image_type)
      puts "Error: Invalid image type. Must be one of: #{valid_image_types.join(', ')}"
      exit 1
    end

    image_type_display = image_type.nil? ? "all types" : image_type.gsub("_", " ")

    if project_id.present?
      project = Project.find_by(id: project_id)
      if project.nil?
        puts "Error: Project with ID #{project_id} not found."
        exit 1
      end
      puts "Starting Docuvita DeliveryItem #{image_type_display} upload for Project: #{project.project_number} (Count: #{upload_count})..."
    else
      puts "Starting Docuvita DeliveryItem #{image_type_display} upload for ALL projects (Count: #{upload_count})..."
    end
    puts "--------------------------------------------------"

    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    total_processed = 0

    # First, check if there are any DeliveryItem records with the requested images
    total_delivery_items = DeliveryItem.count
    puts "Total DeliveryItem records in database: #{total_delivery_items}"

    # Check how many have attached images using ActiveStorage directly
    if image_type.nil?
      # Check counts for all image types
      valid_image_types.each do |img_type|
        count = ActiveStorage::Attachment.where(record_type: "DeliveryItem", name: img_type).count
        puts "Total DeliveryItem records with #{img_type.gsub('_', ' ')} attached: #{count}"
      end

      # Check if any attachments exist
      total_attachments = ActiveStorage::Attachment.where(record_type: "DeliveryItem", name: valid_image_types).count
      if total_attachments == 0
        puts "No DeliveryItem records found with any attached images. Nothing to migrate."
        exit 0
      end
    else
      # Check count for the specific image type
      attachments_count = ActiveStorage::Attachment.where(record_type: "DeliveryItem", name: image_type).count
      puts "Total DeliveryItem records with #{image_type.gsub('_', ' ')} attached: #{attachments_count}"

      if attachments_count == 0
        puts "No DeliveryItem records found with attached #{image_type.gsub('_', ' ')}. Nothing to migrate."
        exit 0
      end
    end

    # Base query - get delivery_items that have the requested images attached
    base_query = DeliveryItem.includes(:docuvita_documents, incoming_delivery: :project)

    if image_type.nil?
      # For all image types, use a more complex query
      join_conditions = []

      valid_image_types.each_with_index do |img_type, index|
        join_alias = "att#{index + 1}"
        base_query = base_query.joins("LEFT JOIN active_storage_attachments AS #{join_alias} ON #{join_alias}.record_id = delivery_items.id AND #{join_alias}.record_type = 'DeliveryItem' AND #{join_alias}.name = '#{img_type}'")
        join_conditions << "#{join_alias}.id IS NOT NULL"
      end

      base_query = base_query.where(join_conditions.join(" OR "))
    else
      # For a specific image type
      base_query = base_query.joins("INNER JOIN active_storage_attachments ON active_storage_attachments.record_id = delivery_items.id AND active_storage_attachments.record_type = 'DeliveryItem' AND active_storage_attachments.name = '#{image_type}'")
    end

    base_query = base_query.distinct

    # Filter by project if specified
    if project_id.present?
      base_query = base_query.joins(incoming_delivery: :project).where(incoming_deliveries: { project_id: project_id })
    end

    puts "Found #{base_query.count} DeliveryItem records with the requested images to process"

    base_query.find_in_batches(batch_size: 20) do |batch|
      puts "Processing batch of #{batch.size} delivery items..."

      batch.each do |delivery_item|
        break if uploaded_count >= upload_count

        project_number = delivery_item.incoming_delivery&.project&.project_number || "Unknown"
        puts "\nProcessing DeliveryItem ##{delivery_item.id} (Project: #{project_number}, Tag: #{delivery_item.tag_number})..."

        # Process each image type
        image_types_to_process = image_type.nil? ? valid_image_types : [ image_type ]

        image_types_to_process.each do |img_type|
          # Skip if we've reached our upload count
          break if uploaded_count >= upload_count

          # Convert image_type to document_sub_type (e.g., "on_hold_images" -> "on_hold_image")
          document_sub_type = img_type.singularize

          # Check if already has Docuvita documents for this image type
          existing_docuvita_docs = delivery_item.docuvita_documents.where(document_sub_type: document_sub_type)

          if existing_docuvita_docs.exists?
            puts "  [SKIP] Already has #{existing_docuvita_docs.count} #{img_type.gsub('_', ' ')} in Docuvita."
            skipped_count += 1
            next
          end

          # Check for attached images of this type
          unless delivery_item.send(img_type).attached?
            puts "  [SKIP] No #{img_type.gsub('_', ' ')} attached."
            skipped_count += 1
            next
          end

          # Process each attached image
          delivery_item.send(img_type).each_with_index do |image, index|
            # Skip if we've reached our upload count
            break if uploaded_count >= upload_count

            begin
              # Get the attached file and prepare for upload
              image_blob = image.blob
              original_filename = image_blob.filename.to_s

              puts "  Uploading #{img_type.gsub('_', ' ')} #{index + 1}/#{delivery_item.send(img_type).count}: '#{original_filename}' (DeliveryItem ##{delivery_item.id})..."

              # Process the file using ActiveStorage's open method
              image.open do |tempfile|
                # Create a temporary file that mimics an uploaded file
                uploaded_file = ActionDispatch::Http::UploadedFile.new(
                  tempfile: tempfile,
                  filename: original_filename,
                  type: image_blob.content_type
                )

                # Use the model's upload method from DocuvitaUploadable concern
                delivery_item.upload_image_to_docuvita(uploaded_file, original_filename, document_sub_type, "delivery_item")

                # After upload, find the newly created document
                new_doc = delivery_item.docuvita_documents.where(document_sub_type: document_sub_type).order(created_at: :desc).first

                if new_doc
                  puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
                  ProjectLog.info("Docuvita upload success via rake task",
                                source: "RakeTask",
                                metadata: {
                                  delivery_item_id: delivery_item.id,
                                  tag_number: delivery_item.tag_number,
                                  docuvita_object_id: new_doc.docuvita_object_id,
                                  filename: original_filename,
                                  image_type: img_type
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
              puts "  [ERROR] Exception during upload for DeliveryItem ##{delivery_item.id}, #{img_type.gsub('_', ' ')} '#{original_filename}': #{e.message}"
              ProjectLog.error("Docuvita upload exception",
                             source: "RakeTask",
                             metadata: {
                               delivery_item_id: delivery_item.id,
                               tag_number: delivery_item.tag_number,
                               filename: original_filename,
                               image_type: img_type,
                               error: e.message,
                               backtrace: e.backtrace.first(5).join("\n")
                             })
              error_count += 1
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
