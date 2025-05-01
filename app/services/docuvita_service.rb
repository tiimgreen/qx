require "net/http"
require "uri"
require "json"
require "net/http/post/multipart"

module DocuvitaService
  class Client
    def initialize(base_url, session_guid)
      @base_url = base_url
      @session_guid = session_guid
      ProjectLog.info("Initializing DocuvitaService", source: "DocuvitaService", metadata: { base_url: @base_url })
    end

    # Get object properties
    def get_object_properties(object_id)
      ProjectLog.info("Getting object properties", source: "DocuvitaService", metadata: { object_id: object_id })
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
      ProjectLog.info("Getting new object properties", source: "DocuvitaService", metadata: { object_type_id: object_type_id })
      uri = URI("#{@base_url}/getobjectproperties")
      params = {
        format: "json",
        Purpose: "NewObject", # Indicate request is for a new object template
        sessionguid: @session_guid,
        ObjectTypeId: object_type_id
      }
      get_request(uri, params)
    end


    # Create object using setobject endpoint (simpler payload structure)
    def set_object(parent_object_id, object_type_id, name, options = {})
      ProjectLog.info("Creating object record (SetObject)", source: "DocuvitaService", metadata: { name: name })
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

      post_request(uri, payload)
    end

    # Upload file content using GUID from SetObject response
    def upload_file(file_path, guid)
      ProjectLog.info("Uploading file", source: "DocuvitaService", metadata: { file_path: file_path, guid: guid })

      uri = URI("#{@base_url}/fileupload")

      # Use lowercase guid parameter as seen in the Postman collection
      params = {
        guid: guid  # Lowercase guid parameter
      }

      # Add query parameters to URI
      uri.query = URI.encode_www_form(params)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
      http.read_timeout = 30
      http.open_timeout = 30

      # Open the file and create the multipart request directly
      File.open(file_path) do |file|
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
        response = http.request(request)

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
      ProjectLog.info("Getting document content", source: "DocuvitaService", metadata: { object_id: object_id })
      uri = URI("#{@base_url}/getdocument")

      # Set query parameters
      params = {
        objectid: object_id,
        SessionGuid: @session_guid
      }

      # Add query parameters to URI
      uri.query = URI.encode_www_form(params)

      # Create HTTP client
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
      http.read_timeout = 30
      http.open_timeout = 30

      # Create GET request
      request = Net::HTTP::Get.new(uri)

      # Send the request
      response = http.request(request)

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

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
      http.read_timeout = 30
      http.open_timeout = 30

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      response = http.request(request)

      handle_response(response)
    end

    # POST request helper (ensure it handles payload correctly, revert param logic)
    def post_request(uri, body_hash)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      # TODO: Remove this for production or configure properly
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = body_hash.to_json

      response = http.request(request)
      handle_response(response)
    end

    # def post_multipart(uri, body, params)
    #   uri.query = URI.encode_www_form(params)

    #   http = Net::HTTP.new(uri.host, uri.port)
    #   http.use_ssl = uri.scheme == "https"
    #   http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
    #   http.read_timeout = 30
    #   http.open_timeout = 30

    #   # Get the file from the body hash - it could be using an empty string key
    #   file_io = body[""] || body[:file]
    #   unless file_io
    #     # Basic error handling if the expected structure isn't found
    #     raise ArgumentError, "Multipart body must contain a file IO object"
    #   end

    #   # Use UploadIO from multipart-post gem
    #   upload_io_object = UploadIO.new(
    #     file_io,
    #     "application/octet-stream", # Standard MIME type for binary data
    #     File.basename(file_io.path) # Extract filename from the IO path
    #   )

    #   # Create a multipart POST request with an empty key for the file
    #   request = Net::HTTP::Post::Multipart.new(
    #     uri.path,
    #     "" => upload_io_object  # Empty key for the file
    #   )

    #   response = http.request(request)

    #   handle_response(response)
    # end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError => e
          ProjectLog.error("Invalid JSON response from docuvita",
                          source: "DocuvitaService",
                          details: e.message,
                          metadata: {
                            url: response.uri,
                            response_code: response.code,
                            response_body_sample: response.body[0..100]
                          })
          raise "Invalid JSON response from docuvita. First 100 chars: #{response.body[0..100]}..."
        end
      else
        ProjectLog.error("Docuvita API error",
                        source: "DocuvitaService",
                        metadata: {
                          url: response.uri,
                          response_code: response.code,
                          response_message: response.message
                        })
        raise "API Error: #{response.code} - #{response.message}"
      end
    end
  end
end
