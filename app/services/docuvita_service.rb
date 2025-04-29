require "net/http"
require "uri"
require "json"
require "net/http/post/multipart"

module DocuvitaService
  class Client
    def initialize(base_url, session_guid)
      @base_url = base_url
      @session_guid = session_guid
      Rails.logger.info "Initializing DocuvitaService with base_url: #{@base_url}"
    end

    # Get object properties
    def get_object_properties(object_id)
      Rails.logger.info "Getting object properties for ID: #{object_id}"
      uri = URI("#{@base_url}/getobject")
      params = {
        format: "json",
        objectid: object_id,
        SessionGuid: @session_guid
      }
      get_request(uri, params)
    end

    # Get new object properties structure for creating a new object
    def get_new_object_properties(object_type_id)
      Rails.logger.info "Getting new object properties structure for ObjectTypeId: #{object_type_id}"
      uri = URI("#{@base_url}/getobjectproperties")
      params = {
        format: "json",
        Purpose: "NewObject", # Indicate request is for a new object template
        sessionguid: @session_guid,
        ObjectTypeId: object_type_id
      }
      get_request(uri, params)
    end

    # Create object record with metadata (SetObjectProperties)
    # Takes the full list/array of property objects (obtained from get_new_object_properties and modified),
    # the original filename, and an optional version comment.
    # Returns the response, which should include the DocUploadGuid for the subsequent file upload.
    def set_object_properties(property_list, original_filename, version_comment = "File Upload")
      Rails.logger.info "Creating object record (SetObjectProperties) for file: #{original_filename}"
      uri = URI("#{@base_url}/setobjectproperties") # Use /setobjectproperties endpoint

      # Construct payload according to API documentation (matching C# example)
      payload = {
        SessionGuid: @session_guid,
        ObjectPropertyList: property_list, # Expecting the full list of property objects
        VersionOriginalFilename: original_filename,
        VersionComment: version_comment
      }
      Rails.logger.debug "SetObjectProperties Payload: #{payload.inspect}" # Log the payload structure

      # Use the standard post_request
      post_request(uri, payload)
    end

    # Create object using setobject endpoint (simpler payload structure)
    def set_object(parent_object_id, object_type_id, name, options = {})
      Rails.logger.info "Creating object record (SetObject) with name: #{name}"
      uri = URI("#{@base_url}/setobject")

      # Construct payload according to the Postman collection example
      object_to_save = {
        # Empty extended attribute objects as shown in Postman
        ExBA: {},
        ExCA: {},
        ExDA: {},
        ExNA: {},
        ExSA: {},
        ExTA: {},
        # Core object properties
        Parentobject: parent_object_id.to_i,
        Objecttype: object_type_id.to_i,
        Name: name,
        Description: options[:description] || "",
        Documenttype: options[:document_type] || "",
        Vouchertype: options[:voucher_type] || "",
        Vouchernumber: options[:voucher_number] || "",
        Externalvouchernumber: options[:external_voucher_number] || "",
        Transactionkey: options[:transaction_key] || "",
        Transactiontype: options[:transaction_type] || "",
        Systemreference: options[:system_reference] || 1
      }

      payload = {
        ObjectToSave: object_to_save,
        SessionGuid: @session_guid,
        VersionOriginalFilename: options[:version_original_filename] || ""
      }

      Rails.logger.debug "SetObject Payload: #{payload.inspect}"
      Rails.logger.debug "SetObject URL: #{uri}"
      post_request(uri, payload)
    end

    # Upload file content using GUID from SetObject response
    def upload_file(file_path, guid)
      Rails.logger.info "Uploading file: #{file_path} with GUID: #{guid}"

      # Add more debugging
      puts "DEBUG: GUID for upload: #{guid.inspect}"
      puts "DEBUG: GUID class: #{guid.class}"
      puts "DEBUG: GUID empty?: #{guid.empty?}" if guid.respond_to?(:empty?)

      uri = URI("#{@base_url}/fileupload")

      # Use lowercase guid parameter as seen in the Postman collection
      params = {
        guid: guid  # Lowercase guid parameter
      }

      # Add query parameters to URI
      uri.query = URI.encode_www_form(params)

      # Log the full URL for debugging
      puts "DEBUG: Full upload URL: #{uri}"
      Rails.logger.debug "Making file upload request to: #{uri}"

      # Create HTTP client
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
      http.read_timeout = 30
      http.open_timeout = 30

      # Open the file and create the multipart request directly
      File.open(file_path) do |file|
        # Create upload IO object
        upload_io = UploadIO.new(
          file,
          "application/octet-stream",
          File.basename(file_path)
        )

        # Create multipart request with empty key for the file and include query string
        path_with_query = uri.query.nil? ? uri.path : "#{uri.path}?#{uri.query}"
        request = Net::HTTP::Post::Multipart.new(
          path_with_query,
          "" => upload_io
        )

        # Send the request
        Rails.logger.debug "Request headers: #{request.to_hash}"
        response = http.request(request)
        Rails.logger.debug "Response code: #{response.code}"
        Rails.logger.debug "Response headers: #{response.to_hash}"

        # Handle the response
        return handle_response(response)
      end
    end

    # Set version
    def set_version(object_id, original_filename, checking = true)
      uri = URI("#{@base_url}/setversion")
      body = {
        objectid: object_id,
        checking: checking,
        VersionOriginalFilename: original_filename,
        sessionguid: @session_guid
      }
      post_request(uri, body)
    end

    # Get object
    def get_object(object_id)
      uri = URI("#{@base_url}/getobject")
      params = {
        objectid: object_id,
        SessionGuid: @session_guid,
        format: "json"
      }
      get_request(uri, params)
    end

    # Get document content using object ID
    def get_document(object_id)
      Rails.logger.info "Getting document for object ID: #{object_id}"
      uri = URI("#{@base_url}/getdocument")

      # Set query parameters
      params = {
        objectid: object_id,
        SessionGuid: @session_guid
      }

      # Add query parameters to URI
      uri.query = URI.encode_www_form(params)

      # Log the full URL for debugging
      Rails.logger.debug "Making get_document request to: #{uri}"

      # Create HTTP client
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
      http.read_timeout = 30
      http.open_timeout = 30

      # Create GET request
      request = Net::HTTP::Get.new(uri)

      # Send the request
      Rails.logger.debug "Request headers: #{request.to_hash}"
      response = http.request(request)
      Rails.logger.debug "Response code: #{response.code}"
      Rails.logger.debug "Response headers: #{response.to_hash}"

      # For document downloads, we want to return the raw response if successful
      if response.code.to_i == 200
        response.body
      else
        # If there's an error, use the handle_response method to parse the error
        handle_response(response)
      end
    end

    private

    def get_request(uri, params)
      uri.query = URI.encode_www_form(params)
      Rails.logger.debug "Making GET request to: #{uri}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
      http.read_timeout = 30
      http.open_timeout = 30

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      Rails.logger.debug "Request headers: #{request.to_hash}"
      response = http.request(request)
      Rails.logger.debug "Response code: #{response.code}"
      Rails.logger.debug "Response headers: #{response.to_hash}"

      handle_response(response)
    end

    # POST request helper (ensure it handles payload correctly, revert param logic)
    def post_request(uri, body_hash)
      Rails.logger.debug "Making POST request to: #{uri}"
      Rails.logger.debug "Request body: #{body_hash.to_json}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      # TODO: Remove this for production or configure properly
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = body_hash.to_json

      Rails.logger.debug "Request headers: #{request.to_hash}"
      response = http.request(request)
      handle_response(response)
    end

    def post_multipart(uri, body, params)
      uri.query = URI.encode_www_form(params)
      Rails.logger.debug "Making multipart POST request to: #{uri}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
      http.read_timeout = 30
      http.open_timeout = 30

      # Get the file from the body hash - it could be using an empty string key
      file_io = body[""] || body[:file]
      unless file_io
        # Basic error handling if the expected structure isn't found
        raise ArgumentError, "Multipart body must contain a file IO object"
      end

      # Use UploadIO from multipart-post gem
      upload_io_object = UploadIO.new(
        file_io,
        "application/octet-stream", # Standard MIME type for binary data
        File.basename(file_io.path) # Extract filename from the IO path
      )

      # Create a multipart POST request with an empty key for the file
      request = Net::HTTP::Post::Multipart.new(
        uri.path,
        "" => upload_io_object  # Empty key for the file
      )

      Rails.logger.debug "Request headers: #{request.to_hash}"
      response = http.request(request)
      Rails.logger.debug "Response code: #{response.code}"
      Rails.logger.debug "Response headers: #{response.to_hash}"

      handle_response(response)
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        begin
          Rails.logger.debug "Response body: #{response.body[0..500]}"
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          Rails.logger.error "Invalid JSON response from docuvita:"
          Rails.logger.error "URL: #{response.uri}"
          Rails.logger.error "Response code: #{response.code}"
          Rails.logger.error "Response headers: #{response.to_hash}"
          Rails.logger.error "Response body: #{response.body[0..1000]}"
          Rails.logger.error "Parse error: #{e.message}"
          raise "Invalid JSON response from docuvita. First 100 chars: #{response.body[0..100]}..."
        end
      else
        Rails.logger.error "Docuvita API error:"
        Rails.logger.error "URL: #{response.uri}"
        Rails.logger.error "Response code: #{response.code}"
        Rails.logger.error "Response headers: #{response.to_hash}"
        Rails.logger.error "Response body: #{response.body[0..1000]}"
        raise "API Error: #{response.code} - #{response.message}"
      end
    end
  end
end
