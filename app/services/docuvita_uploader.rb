class DocuvitaUploader
  # Default object type ID for isometry documents
  ISOMETRY_OBJECT_TYPE_ID = 29 # Replace with your actual object type ID

  def initialize(options = {})
    @client = DocuvitaService::Client.new(
      DOCUVITA_CONFIG[:base_url],
      DOCUVITA_CONFIG[:session_guid]
    )
    @object_type_id = options[:object_type_id] || ISOMETRY_OBJECT_TYPE_ID
    @parent_object_id = options[:parent_object_id] || DOCUVITA_CONFIG[:parent_object_id]
    @system_reference = options[:system_reference] || DOCUVITA_CONFIG[:system_reference]
  end

  def upload_file(file_path, options = {})
    # Extract filename from path
    original_filename = File.basename(file_path)

    # Set default options
    doc_name = options[:name] || original_filename
    description = options[:description] || ""

    # Log the upload attempt
    ProjectLog.info("Uploading file to Docuvita",
                   source: "DocuvitaUploader",
                   metadata: {
                     file_path: file_path,
                     parent_object_id: @parent_object_id,
                     object_type_id: @object_type_id,
                     doc_name: doc_name
                   })

    # Step 1: Create object in Docuvita
    set_object_response = @client.set_object(
      @parent_object_id,
      @object_type_id,
      doc_name,
      {
        description: description,
        version_original_filename: original_filename,
        system_reference: @system_reference
      }
    )

    # Extract the object ID from the response
    object_id = set_object_response["SavedObject"]["Objectid"]
    unless object_id
      raise "Failed to get Object ID from Docuvita"
    end

    # Step 2: Get upload GUID
    set_version_response = @client.set_version(object_id, original_filename, true)

    # Extract the upload GUID
    upload_guid = set_version_response["DocUploadGuid"]
    unless upload_guid
      raise "Failed to get Upload GUID from Docuvita"
    end

    # Add a small delay before uploading (sometimes APIs need a moment to register the GUID)
    sleep(1)

    # Step 3: Upload the file
    upload_response = @client.upload_file(file_path, upload_guid)

    # Return the object ID and response for reference
    {
      object_id: object_id,
      response: upload_response
    }
  end

  def upload_io(io, filename, options = {})
    # Create a temporary file from the IO with binary mode
    temp_file = Tempfile.new([ "docuvita_upload", File.extname(filename) ])
    begin
      # Write the IO content to the temp file in binary mode
      io.binmode if io.respond_to?(:binmode)
      io.rewind

      # Ensure we're writing in binary mode
      temp_file.binmode
      temp_file.write(io.read)
      temp_file.close

      # Upload the temp file
      result = upload_file(temp_file.path, options.merge(name: filename))

      result
    ensure
      # Clean up the temp file
      temp_file.unlink if temp_file && File.exist?(temp_file.path)
    end
  end

  def download_document(object_id)
    @client.get_document(object_id)
  end
end
