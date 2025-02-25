# Use MiniMagick for image processing
Rails.application.config.active_storage.variant_processor = :mini_magick

# Configure the content types that can be processed
Rails.application.config.active_storage.variable_content_types = %w(
  image/png
  image/gif
  image/jpg
  image/jpeg
  image/webp
)

# Configure web image content types
Rails.application.config.active_storage.web_image_content_types = %w(
  image/png
  image/gif
  image/jpg
  image/jpeg
  image/webp
)

# Set the queue for background job processing
Rails.application.config.active_storage.queues.analysis = :active_storage_analysis
Rails.application.config.active_storage.queues.purge = :active_storage_purge

# Configure variant processing options
Rails.application.config.active_storage.variant_options = {
  # Specify the sRGB color profile
  srgb: true,
  # Strip metadata from processed images
  strip: true,
  # Set a reasonable quality level for JPEG compression
  quality: 80
}
