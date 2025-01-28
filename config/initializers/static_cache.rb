# Configure static file serving for videos
Rails.application.config.public_file_server.headers = {
  "Cache-Control" => "public, max-age=31536000",
  "Expires" => 1.year.from_now.to_formatted_s(:rfc822)
}
