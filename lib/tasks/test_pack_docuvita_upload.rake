# lib/tasks/test_pack_docuvita_upload.rake
namespace :docuvita do
  desc "Upload TestPack on_hold_images to Docuvita. Usage: rails docuvita:upload_test_pack_images [count] [project_id] [test_pack_type]"
  task :upload_test_pack_images, [ :count, :project_id, :test_pack_type ] => :environment do |_task, args|
    # Get the number of images to upload from args or prompt for it
    upload_count = if args[:count].present?
                     args[:count].to_i
    else
                     print "Enter the number of test pack images to upload (default: 10): "
                     input = STDIN.gets.chomp
                     input.present? ? input.to_i : 10
    end

    # Get the project ID if provided
    project_id = args[:project_id]

    # Get the test pack type if provided (pressure_test or leak_test)
    test_pack_type = args[:test_pack_type]

    unless test_pack_type.nil? || TestPack::TEST_PACK_TYPES.include?(test_pack_type)
      puts "Error: Invalid test pack type. Must be one of: #{TestPack::TEST_PACK_TYPES.join(', ')}"
      exit 1
    end

    test_pack_type_display = test_pack_type.nil? ? "all types" : test_pack_type

    if project_id.present?
      project = Project.find_by(id: project_id)
      if project.nil?
        puts "Error: Project with ID #{project_id} not found."
        exit 1
      end
      puts "Starting Docuvita TestPack (#{test_pack_type_display}) on_hold_images upload for Project: #{project.project_number} (Count: #{upload_count})..."
    else
      puts "Starting Docuvita TestPack (#{test_pack_type_display}) on_hold_images upload for ALL projects (Count: #{upload_count})..."
    end
    puts "--------------------------------------------------"

    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    total_processed = 0

    # First, check if there are any TestPack records with on_hold_images
    total_test_packs = TestPack.count
    puts "Total TestPack records in database: #{total_test_packs}"

    # Check how many have attached images using ActiveStorage directly
    attachments_count = ActiveStorage::Attachment.where(record_type: "TestPack", name: "on_hold_images").count
    puts "Total TestPack records with on_hold_images attached: #{attachments_count}"

    if attachments_count == 0
      puts "No TestPack records found with attached on_hold_images. Nothing to migrate."
      exit 0
    end

    # Base query - get test_packs that have on_hold_images attached
    base_query = TestPack.includes(:docuvita_documents, :project)
                         .joins("INNER JOIN active_storage_attachments ON active_storage_attachments.record_id = test_packs.id AND active_storage_attachments.record_type = 'TestPack' AND active_storage_attachments.name = 'on_hold_images'")
                         .distinct

    # Filter by project if specified
    base_query = base_query.where(project_id: project_id) if project_id.present?

    # Filter by test pack type if specified
    base_query = base_query.where(test_pack_type: test_pack_type) if test_pack_type.present?

    puts "Found #{base_query.count} TestPack records with on_hold_images to process"

    base_query.find_in_batches(batch_size: 20) do |batch|
      puts "Processing batch of #{batch.size} test packs..."

      batch.each do |test_pack|
        break if uploaded_count >= upload_count

        puts "\nProcessing TestPack ##{test_pack.id} (Project: #{test_pack.project.project_number}, Type: #{test_pack.test_pack_type})..."

        # Check if already has Docuvita documents for on_hold_images
        existing_docuvita_docs = test_pack.docuvita_documents.where(document_sub_type: "on_hold_image")

        if existing_docuvita_docs.exists?
          puts "  [SKIP] Already has #{existing_docuvita_docs.count} on_hold_images in Docuvita."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Check for attached on_hold_images
        unless test_pack.on_hold_images.attached?
          puts "  [SKIP] No on_hold_images attached."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Process each attached image
        test_pack.on_hold_images.each_with_index do |image, index|
          begin
            # Get the attached file and prepare for upload
            image_blob = image.blob
            original_filename = image_blob.filename.to_s

            puts "  Uploading image #{index + 1}/#{test_pack.on_hold_images.count}: '#{original_filename}' (TestPack ##{test_pack.id})..."

            # Process the file using ActiveStorage's open method
            image.open do |tempfile|
              # Create a temporary file that mimics an uploaded file
              uploaded_file = ActionDispatch::Http::UploadedFile.new(
                tempfile: tempfile,
                filename: original_filename,
                type: image_blob.content_type
              )

              # Use the model's upload method from DocuvitaUploadable concern
              test_pack.upload_image_to_docuvita(uploaded_file, original_filename, "on_hold_image", "test_pack")

              # After upload, find the newly created document
              new_doc = test_pack.docuvita_documents.where(document_sub_type: "on_hold_image").order(created_at: :desc).first

              if new_doc
                puts "  [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
                ProjectLog.info("Docuvita upload success via rake task",
                              source: "RakeTask",
                              metadata: {
                                test_pack_id: test_pack.id,
                                test_pack_type: test_pack.test_pack_type,
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
            puts "  [ERROR] Exception during upload for TestPack ##{test_pack.id}, image '#{original_filename}': #{e.message}"
            ProjectLog.error("Docuvita upload exception",
                           source: "RakeTask",
                           metadata: {
                             test_pack_id: test_pack.id,
                             test_pack_type: test_pack.test_pack_type,
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
