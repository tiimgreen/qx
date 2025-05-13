# lib/tasks/site_assembly_docuvita_upload.rake
namespace :docuvita do
  desc "Upload SiteAssembly on_hold_images to Docuvita. Usage: rails docuvita:upload_site_assembly_images [count] [project_id]"
  task :upload_site_assembly_images, [ :count, :project_id ] => :environment do |_task, args|
    # Get the number of images to upload from args or prompt for it
    upload_count = if args[:count].present?
                     args[:count].to_i
    else
                     print "Enter the number of site assembly images to upload (default: 10): "
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
      puts "Starting Docuvita SiteAssembly on_hold_images upload for Project: #{project.project_number} (Count: #{upload_count})..."
    else
      puts "Starting Docuvita SiteAssembly on_hold_images upload for ALL projects (Count: #{upload_count})..."
    end
    puts "--------------------------------------------------"

    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    total_processed = 0

    # First, check if there are any SiteAssembly records with on_hold_images
    total_site_assemblies = SiteAssembly.count
    puts "Total SiteAssembly records in database: #{total_site_assemblies}"

    # Check how many have attached images using ActiveStorage directly
    attachments_count = ActiveStorage::Attachment.where(record_type: "SiteAssembly", name: "on_hold_images").count
    puts "Total SiteAssembly records with on_hold_images attached: #{attachments_count}"

    if attachments_count == 0
      puts "No SiteAssembly records found with attached on_hold_images. Nothing to migrate."
      exit 0
    end

    # Base query - get site_assemblies that have on_hold_images attached
    base_query = SiteAssembly.includes(:docuvita_documents, :project)
                               .joins("INNER JOIN active_storage_attachments ON active_storage_attachments.record_id = site_assemblies.id AND active_storage_attachments.record_type = 'SiteAssembly' AND active_storage_attachments.name = 'on_hold_images'")
                               .distinct

    # Filter by project if specified
    base_query = base_query.where(project_id: project_id) if project_id.present?

    puts "Found #{base_query.count} SiteAssembly records with on_hold_images to process"

    base_query.find_in_batches(batch_size: 20) do |batch|
      puts "Processing batch of #{batch.size} site assemblies..."

      batch.each do |site_assembly|
        break if uploaded_count >= upload_count

        puts "\nProcessing SiteAssembly ##{site_assembly.id} (Project: #{site_assembly.project.project_number})..."

        # Check if already has Docuvita documents for on_hold_images
        existing_docuvita_docs = site_assembly.docuvita_documents.where(document_sub_type: "on_hold_image")

        if existing_docuvita_docs.exists?
          puts "  [SKIP] Already has #{existing_docuvita_docs.count} on_hold_images in Docuvita."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Check for attached on_hold_images
        unless site_assembly.on_hold_images.attached?
          puts "  [SKIP] No on_hold_images attached."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Process each attached image
        site_assembly.on_hold_images.each_with_index do |image, index|
          begin
            # Get the attached file and prepare for upload
            image_blob = image.blob
            original_filename = image_blob.filename.to_s

            puts "  Uploading image #{index + 1}/#{site_assembly.on_hold_images.count}: '#{original_filename}' (SiteAssembly ##{site_assembly.id})..."

            # Process the file using ActiveStorage's open method
            image.open do |tempfile|
              # Create a temporary file that mimics an uploaded file
              uploaded_file = ActionDispatch::Http::UploadedFile.new(
                tempfile: tempfile,
                filename: original_filename,
                type: image_blob.content_type
              )

              # Use the model's upload method from DocuvitaUploadable concern
              site_assembly.upload_image_to_docuvita(uploaded_file, original_filename, "on_hold_image", "site_assembly")

              # After upload, find the newly created document
              new_doc = site_assembly.docuvita_documents.where(document_sub_type: "on_hold_image").order(created_at: :desc).first

              if new_doc
                puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
                ProjectLog.info("Docuvita upload success via rake task",
                              source: "RakeTask",
                              metadata: {
                                site_assembly_id: site_assembly.id,
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
            puts "  [ERROR] Exception during upload for SiteAssembly ##{site_assembly.id}, image '#{original_filename}': #{e.message}"
            ProjectLog.error("Docuvita upload exception",
                           source: "RakeTask",
                           metadata: {
                             site_assembly_id: site_assembly.id,
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
