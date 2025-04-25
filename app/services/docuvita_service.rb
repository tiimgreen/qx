require "net/http"
require "uri"
require "json"

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

    # Get new object properties for creating a new object
    def get_new_object_properties(object_type_id)
      uri = URI("#{@base_url}/getobjectproperties")
      params = {
        format: "json",
        Purpose: "NewObject",
        sessionguid: @session_guid,
        ObjectTypeId: object_type_id
      }
      get_request(uri, params)
    end

    # Set object properties
    def set_object_properties(properties)
      uri = URI("#{@base_url}/setobjectproperties")
      params = { sessionguid: @session_guid }
      post_request(uri, properties, params)
    end

    # Upload file
    def upload_file(file_path, guid)
      uri = URI("#{@base_url}/fileupload")
      params = { guid: guid }

      # Create multipart form data
      File.open(file_path) do |file|
        body = { file: file }
        post_multipart(uri, body, params)
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

    def post_request(uri, body, params = {})
      uri.query = URI.encode_www_form(params) unless params.empty?
      Rails.logger.debug "Making POST request to: #{uri}"
      Rails.logger.debug "Request body: #{body.to_json}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Skip SSL verification for self-signed cert
      http.read_timeout = 30
      http.open_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = body.to_json

      Rails.logger.debug "Request headers: #{request.to_hash}"
      response = http.request(request)
      Rails.logger.debug "Response code: #{response.code}"
      Rails.logger.debug "Response headers: #{response.to_hash}"

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

      request = Net::HTTP::Post.new(uri)
      form_data = body.transform_values { |v| UploadIO.new(v, "application/octet-stream", File.basename(v.path)) }
      request.set_form(form_data, "multipart/form-data")

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
