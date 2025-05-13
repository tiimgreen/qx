# lib/tasks/isometry_docuvita_upload.rake
namespace :docuvita do
  desc "Upload Isometry attachments to Docuvita with latest implementation. Usage: rails docuvita:upload_isometry_attachments[project_id,count]"
  task :upload_isometry_attachments, [ :project_id, :count ] => :environment do |_task, args|
    # Validate project_id
    project_id = args[:project_id]
    unless project_id
      puts "ERROR: Project ID is required."
      puts "Usage: rails 'docuvita:upload_isometry_attachments[your_project_id,optional_count]'"
      abort
    end

    project = Project.find_by(id: project_id)
    unless project
      puts "ERROR: Project with ID #{project_id} not found."
      abort
    end

    # Get the number of isometries to process from args or prompt for it
    upload_count = if args[:count].present?
                     args[:count].to_i
    else
                     print "Enter the number of isometries to process (default: 10): "
                     input = STDIN.gets.chomp
                     input.present? ? input.to_i : 10
    end

    project_display_name = project.project_number ? "#{project.name} (#{project.project_number})" : project.name
    puts "Starting Docuvita Isometry attachments upload for Project: #{project_display_name} (ID: #{project.id})"
    puts "Upload count: #{upload_count}"
    puts "--------------------------------------------------"

    uploaded_count = 0
    skipped_count = 0
    error_count = 0
    total_processed = 0

    # Ask user which type of attachments to upload
    print "Upload isometry PDFs? (Y/n): "
    upload_pdfs = (STDIN.gets.chomp.downcase != "n")

    print "Upload RT images? (Y/n): "
    upload_rt_images = (STDIN.gets.chomp.downcase != "n")

    print "Upload VT images? (Y/n): "
    upload_vt_images = (STDIN.gets.chomp.downcase != "n")

    print "Upload PT images? (Y/n): "
    upload_pt_images = (STDIN.gets.chomp.downcase != "n")

    print "Upload on-hold images? (Y/n): "
    upload_on_hold_images = (STDIN.gets.chomp.downcase != "n")

    unless upload_pdfs || upload_rt_images || upload_vt_images || upload_pt_images || upload_on_hold_images
      puts "No attachment types selected for upload. Exiting."
      return
    end

    puts "Will upload: #{upload_pdfs ? 'PDFs ' : ''}#{upload_rt_images ? 'RT images ' : ''}#{upload_vt_images ? 'VT images ' : ''}#{upload_pt_images ? 'PT images ' : ''}#{upload_on_hold_images ? 'On-Hold images' : ''}"

    # Process isometries
    isometries = project.isometries.includes(:project, :docuvita_documents)

    # Process only the latest revisions by default
    isometries = isometries.where(revision_last: true) unless args[:all_revisions]

    isometries.find_in_batches(batch_size: 50) do |batch|
      puts "Processing batch of #{batch.size} isometries..."

      batch.each do |isometry|
        break if total_processed >= upload_count

        puts "\nProcessing Isometry ##{isometry.id} (Line ID: #{isometry.line_id || 'N/A'})..."

        # Skip if line_id or project_number is missing
        unless isometry.line_id.present? && isometry.project&.project_number.present?
          puts "  [SKIP] Isometry missing Line ID or Project Number required for Docuvita metadata."
          skipped_count += 1
          total_processed += 1
          next
        end

        # Process each attachment type as requested
        if upload_pdfs
          process_isometry_pdfs(isometry, uploaded_count, skipped_count, error_count)
        end

        if upload_rt_images
          process_rt_images(isometry, uploaded_count, skipped_count, error_count)
        end

        if upload_vt_images
          process_vt_images(isometry, uploaded_count, skipped_count, error_count)
        end

        if upload_pt_images
          process_pt_images(isometry, uploaded_count, skipped_count, error_count)
        end

        if upload_on_hold_images
          process_on_hold_images(isometry, uploaded_count, skipped_count, error_count)
        end

        total_processed += 1
      end

      # Break out of the batch processing if we've reached our upload count
      break if total_processed >= upload_count
    end

    puts "\n--------------------------------------------------"
    puts "Task finished. Requested: #{upload_count}, Processed: #{total_processed}, Uploaded: #{uploaded_count}, Skipped: #{skipped_count}, Errors: #{error_count}."
  end

  private

  def process_isometry_pdfs(isometry, uploaded_count, skipped_count, error_count)
    puts "  Processing PDF documents for Isometry ##{isometry.id}..."

    # First check for IsometryDocument PDFs
    isometry_documents = isometry.isometry_documents.select { |doc| doc.pdf.attached? }

    if isometry_documents.empty?
      puts "    [SKIP] No IsometryDocument with an attached PDF found."
      skipped_count += 1
      return
    end

    # Check if already uploaded to Docuvita
    existing_docuvita_docs = isometry.docuvita_documents.where(document_sub_type: "isometry")
    if existing_docuvita_docs.exists?
      puts "    [SKIP] Already uploaded. Docuvita Object ID: #{existing_docuvita_docs.first.docuvita_object_id}"
      skipped_count += 1
      return
    end

    # Process each IsometryDocument with PDF
    isometry_documents.each do |iso_doc|
      begin
        pdf_blob = iso_doc.pdf.blob
        original_filename = pdf_blob.filename.to_s

        puts "    Uploading PDF: '#{original_filename}'"

        iso_doc.pdf.open do |tempfile|
          # Create a temporary file that mimics an uploaded file
          uploaded_file = ActionDispatch::Http::UploadedFile.new(
            tempfile: tempfile,
            filename: original_filename,
            type: pdf_blob.content_type
          )

          # Use the model's upload_pdf_to_docuvita method
          isometry.upload_pdf_to_docuvita(
            uploaded_file,
            original_filename,
            "isometry",
            {
              qr_position: iso_doc.qr_position,
              voucher_number: isometry.line_id,
              transaction_key: isometry.project.project_number,
              description: {
                line_id: isometry.line_id,
                project_number: isometry.project.project_number,
                original_filename: original_filename,
                upload_context: "rake_task"
              }
            }
          )

          # After upload, find the newly created document
          new_doc = isometry.docuvita_documents.where(document_sub_type: "isometry").order(created_at: :desc).first

          if new_doc
            puts "    [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
            ProjectLog.info("Docuvita upload success via rake task",
                          source: "RakeTask",
                          metadata: {
                            project_id: isometry.project_id,
                            isometry_id: isometry.id,
                            docuvita_object_id: new_doc.docuvita_object_id,
                            filename: original_filename
                          })

            uploaded_count += 1
          else
            puts "    [WARNING] Upload may have succeeded but no DocuvitaDocument record was found."
            error_count += 1
          end
        end
      rescue StandardError => e
        puts "    [ERROR] Exception during upload for Isometry ##{isometry.id}: #{e.message}"
        ProjectLog.error("Docuvita upload exception",
                       source: "RakeTask",
                       metadata: {
                         project_id: isometry.project_id,
                         isometry_id: isometry.id,
                         filename: original_filename,
                         error: e.message,
                         backtrace: e.backtrace.first(5).join("\n")
                       })
        error_count += 1
      end
    end
  end

  def process_rt_images(isometry, uploaded_count, skipped_count, error_count)
    process_image_attachments(isometry, "rt_images", "rt_image", uploaded_count, skipped_count, error_count)
  end

  def process_vt_images(isometry, uploaded_count, skipped_count, error_count)
    process_image_attachments(isometry, "vt_images", "vt_image", uploaded_count, skipped_count, error_count)
  end

  def process_pt_images(isometry, uploaded_count, skipped_count, error_count)
    process_image_attachments(isometry, "pt_images", "pt_image", uploaded_count, skipped_count, error_count)
  end

  def process_on_hold_images(isometry, uploaded_count, skipped_count, error_count)
    process_image_attachments(isometry, "on_hold_images", "on_hold_image", uploaded_count, skipped_count, error_count)
  end

  def process_image_attachments(isometry, attachment_name, document_sub_type, uploaded_count, skipped_count, error_count)
    puts "  Processing #{attachment_name.humanize} for Isometry ##{isometry.id}..."

    # Find attachments directly from ActiveStorage
    attachments_query = ActiveStorage::Attachment.where(
      record_type: "Isometry",
      record_id: isometry.id,
      name: attachment_name
    ).includes(:blob)

    if attachments_query.empty?
      puts "    [SKIP] No #{attachment_name.humanize} found."
      skipped_count += 1
      return
    end

    # Process each attachment
    attachments_query.each do |attachment|
      begin
        blob = attachment.blob
        original_filename = blob.filename.to_s

        # Check if this specific image has already been uploaded
        existing_doc = isometry.docuvita_documents.where(
          document_sub_type: document_sub_type,
          filename: original_filename
        ).first

        if existing_doc
          puts "    [SKIP] Image '#{original_filename}' already uploaded. Docuvita Object ID: #{existing_doc.docuvita_object_id}"
          skipped_count += 1
          next
        end

        puts "    Uploading image: '#{original_filename}'"

        blob.open do |tempfile|
          # Create a temporary file that mimics an uploaded file
          uploaded_file = ActionDispatch::Http::UploadedFile.new(
            tempfile: tempfile,
            filename: original_filename,
            type: blob.content_type
          )

          # Use the model's upload_image_to_docuvita method
          isometry.upload_image_to_docuvita(
            uploaded_file,
            original_filename,
            document_sub_type,
            "isometry"
          )

          # After upload, find the newly created document
          new_doc = isometry.docuvita_documents.where(
            document_sub_type: document_sub_type,
            filename: original_filename
          ).order(created_at: :desc).first

          if new_doc
            puts "    [SUCCESS] Uploaded! Docuvita Object ID: #{new_doc.docuvita_object_id}"
            ProjectLog.info("Docuvita upload success via rake task",
                          source: "RakeTask",
                          metadata: {
                            project_id: isometry.project_id,
                            isometry_id: isometry.id,
                            docuvita_object_id: new_doc.docuvita_object_id,
                            filename: original_filename
                          })

            uploaded_count += 1
          else
            puts "    [WARNING] Upload may have succeeded but no DocuvitaDocument record was found."
            error_count += 1
          end
        end
      rescue StandardError => e
        puts "    [ERROR] Exception during upload for Isometry ##{isometry.id}: #{e.message}"
        ProjectLog.error("Docuvita upload exception",
                       source: "RakeTask",
                       metadata: {
                         project_id: isometry.project_id,
                         isometry_id: isometry.id,
                         filename: original_filename,
                         error: e.message,
                         backtrace: e.backtrace.first(5).join("\n")
                       })
        error_count += 1
      end
    end
  end
end
