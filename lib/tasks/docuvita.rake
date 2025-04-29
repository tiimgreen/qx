# lib/tasks/docuvita.rake
namespace :docuvita do
  desc "Upload a file to Docuvita using the provided metadata"
  task :upload, [ :file_path, :object_type_id, :parent_object_id, :doc_name, :voucher_type, :voucher_number, :mandant ] => :environment do |task, args|
    # --- Argument Handling ---
    file_path = args[:file_path]
    object_type_id = args[:object_type_id]&.to_i
    parent_object_id = args[:parent_object_id]&.to_i
    doc_name = args[:doc_name] || "Rake Upload #{Time.now.to_i}"
    voucher_type = args[:voucher_type]
    voucher_number = args[:voucher_number]
    mandant = args[:mandant] || "1" # Default mandant if not provided

    # --- Basic Validation ---
    if file_path.blank? || !File.exist?(file_path)
      puts "Error: File path is required and the file must exist."
      puts "Usage: bundle exec rake 'docuvita:upload[/path/to/your/file.pdf,object_type_id,parent_id,doc_name,voucher_type,voucher_number,mandant]'"
      exit(1) # Exit with error code
    end

    if object_type_id.blank? || parent_object_id.blank?
      puts "Error: Object Type ID and Parent Object ID are required."
      puts "Usage: bundle exec rake 'docuvita:upload[/path/to/your/file.pdf,object_type_id,parent_id,doc_name,voucher_type,voucher_number,mandant]'"
      exit(1) # Exit with error code
    end

    puts "Starting Docuvita upload..."
    puts "  File Path: #{file_path}"
    puts "  Object Type ID: #{object_type_id}"
    puts "  Parent Object ID: #{parent_object_id}"
    puts "  Document Name: #{doc_name}"
    puts "  Voucher Type: #{voucher_type || 'Not Provided'}"
    puts "  Voucher Number: #{voucher_number || 'Not Provided'}"
    puts "  Mandant: #{mandant}"

    # --- Upload Logic (Adapted from the sample method) ---
    begin
      # 1. Initialize the client
      # Ensure your DOCUVITA_CONFIG initializer runs or set ENV vars
      base_url = DOCUVITA_CONFIG[:base_url]
      session_guid = DOCUVITA_CONFIG[:session_guid]

      unless base_url && session_guid
        puts "Error: Docuvita base_url or session_guid is not configured in DOCUVITA_CONFIG."
        exit(1)
      end

      client = DocuvitaService::Client.new(base_url, session_guid)
      original_filename = File.basename(file_path)

      # 2. Get the property structure
      puts "Step 1: Getting new object properties structure..."
      properties_response = client.get_new_object_properties(object_type_id)

      unless properties_response && properties_response["ObjectPropertyList"].is_a?(Array)
        puts "Error: Failed to get object properties structure."
        puts "Response: #{properties_response.inspect}"
        exit(1)
      end
      property_list = properties_response["ObjectPropertyList"]
      puts "  -> Structure received."

      # 3. Modify the properties
      puts "Step 2: Modifying properties..."

      # Make sure these critical fields are set
      parent_object_field = property_list.find { |p| p["FieldName"].upcase == "OBJ_PARENTOBJECT" }
      object_type_field = property_list.find { |p| p["FieldName"].upcase == "OBJ_OBJECTTYPE" }

      # If these critical fields don't exist, add them
      if !parent_object_field
        puts "  -> Adding missing OBJ_PARENTOBJECT field"
        property_list << {
          "FieldName" => "OBJ_PARENTOBJECT",
          "FieldType" => "N",
          "FieldValueNumeric" => parent_object_id.to_i,
          "Required" => true
        }
      end

      if !object_type_field
        puts "  -> Adding missing OBJ_OBJECTTYPE field"
        property_list << {
          "FieldName" => "OBJ_OBJECTTYPE",
          "FieldType" => "N",
          "FieldValueNumeric" => object_type_id.to_i,
          "Required" => true
        }
      end

      # Process each property in the list
      property_list.each do |prop|
        # Use upcase for case-insensitive matching against expected FieldNames
        field_name_upper = prop["FieldName"].upcase
        case field_name_upper
        when "OBJ_PARENTOBJECT"
          prop["FieldValueNumeric"] = parent_object_id.to_i
        when "OBJ_OBJECTTYPE"
          prop["FieldValueNumeric"] = object_type_id.to_i
        when "OBJ_NAME"
          prop["FieldValueString"] = doc_name
        when "OBJ_VOUCHERTYPE"
          prop["FieldValueString"] = voucher_type if voucher_type.present? # Only set if provided
        when "OBJ_VOUCHERNUMBER"
          prop["FieldValueString"] = voucher_number if voucher_number.present? # Only set if provided
        when "MANDANT"
          prop["FieldValueString"] = mandant
        end
      end

      # Print the full property list for debugging
      # puts "DEBUG: Full property list:"
      # pp property_list

      puts "  -> Properties updated."

      # 4. Create the object record
      puts "Step 3: Creating object record (SetObject)..."

      # Step 3.1: Create the object to get an object ID
      set_object_response = client.set_object(
        parent_object_id,
        object_type_id,
        doc_name,
        {
          description: "",
          document_type: "TEST",
          voucher_type: voucher_type,
          voucher_number: voucher_number,
          external_voucher_number: "",
          transaction_key: "",
          transaction_type: "",
          system_reference: 1,
          version_original_filename: original_filename
        }
      )

      # Print the full response for debugging
      puts "DEBUG: Full set_object response:"
      # pp set_object_response

      # Extract the object ID from the response
      object_id = set_object_response["SavedObject"]["Objectid"]
      unless object_id
        puts "Error: Failed to get Object ID."
        puts "Response: #{set_object_response.inspect}"
        exit(1)
      end
      puts "  -> Object created with ID: #{object_id}"

      # Step 3.2: Get the upload GUID using set_version
      puts "Step 4: Getting upload GUID (SetVersion)..."

      set_version_response = client.set_version(object_id, original_filename, true)

      # Print the full response for debugging
      puts "DEBUG: Full set_version response:"
      pp set_version_response

      # Extract the upload GUID
      upload_guid = set_version_response["DocUploadGuid"]
      unless upload_guid
        puts "Error: Failed to get Upload GUID."
        puts "Response: #{set_version_response.inspect}"
        exit(1)
      end
      puts "  -> Upload GUID obtained: #{upload_guid}"

      # Add a small delay before uploading (sometimes APIs need a moment to register the GUID)
      puts "Waiting 2 seconds before uploading..."
      sleep(2)

      # 6. Upload the file
      puts "Step 5: Uploading file content..."

      upload_response = client.upload_file(file_path, upload_guid)
      puts "  -> File upload successful."
      puts "Final API Response:"
      pp upload_response # Pretty print the final response

      puts "\nDocuvita upload completed successfully!"

    rescue => e
      puts "\nError during Docuvita upload process: #{e.message}"
      puts e.backtrace.first(5).join("\n") # Print first few lines of backtrace
      exit(1) # Exit with error code
    end
  end

  desc "Download a document from Docuvita by object ID"
  task :download, [ :object_id, :output_path, :mandant ] => :environment do |task, args|
    object_id = args[:object_id]
    output_path = args[:output_path]
    mandant = args[:mandant] || "1"

    unless object_id && output_path
      puts "Usage: rake docuvita:download[object_id,output_path,mandant]"
      puts "  object_id: The Docuvita object ID of the document to download"
      puts "  output_path: The path where the downloaded document should be saved"
      puts "  mandant: Optional, the mandant ID (default: 1)"
      exit(1)
    end

    puts "Starting Docuvita document download..."
    puts "  Object ID: #{object_id}"
    puts "  Output Path: #{output_path}"
    puts "  Mandant: #{mandant}"

    begin
      # Initialize the Docuvita client
      # Ensure your DOCUVITA_CONFIG initializer runs or set ENV vars
      base_url = DOCUVITA_CONFIG[:base_url]
      session_guid = DOCUVITA_CONFIG[:session_guid]

      unless base_url && session_guid
        puts "Error: Docuvita base_url or session_guid is not configured in DOCUVITA_CONFIG."
        exit(1)
      end

      client = DocuvitaService::Client.new(base_url, session_guid)

      # Get the document
      puts "Downloading document..."
      document_content = client.get_document(object_id)

      # Check if we got an error response (which would be a hash)
      if document_content.is_a?(Hash)
        puts "Error: Failed to download document."
        puts "Response: #{document_content.inspect}"
        exit(1)
      end

      # Save the document to the specified path
      File.open(output_path, "wb") do |file|
        file.write(document_content)
      end

      puts "Document successfully downloaded to: #{output_path}"

    rescue => e
      puts "\nError during Docuvita download process: #{e.message}"
      puts e.backtrace.first(5).join("\n") # Print first few lines of backtrace
      exit(1) # Exit with error code
    end
  end
end
