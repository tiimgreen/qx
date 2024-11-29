class Isometry < ApplicationRecord
  belongs_to :project
  belongs_to :sector, optional: true
  belongs_to :user, optional: true

  include QrCodeable

  has_many_attached :isometry_images
  has_many_attached :on_hold_images

  after_commit :process_isometry_images, on: [:create, :update]

  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze
  PED_CATEGORIES = [ "N/A", "I", "II", "III", "IV" ].freeze

  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }

  # Validations
  validates :received_date, presence: true
  validates :pid_number, presence: true
  validates :system, presence: true
  validates :pipe_class, presence: true
  validates :material, presence: true
  validates :line_id, presence: true, uniqueness: true
  validates :revision_number, presence: true
  validates :page_number, presence: true
  validates :page_total, presence: true
  validates :medium, presence: true

  # Numeric validations
  validates :pipe_length, numericality: { greater_than: 0 }, allow_nil: true
  validates :workshop_sn, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :assembly_sn, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_supports, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_spools, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rt, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :vt2, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :pt2, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Callbacks
  before_save :calculate_total_sn
  before_save :set_on_hold_date

  # Scopes
  scope :active, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }
  scope :on_hold, -> { where.not(on_hold_status: [ nil, "" ]) }
  scope :latest_revision, -> { where(revision_last: true) }
  scope :by_system, ->(system) { where(system: system) }
  scope :by_line_id, ->(line_id) { where(line_id: line_id) }

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"
    where(
      "isometries.line_id LIKE :search OR
       isometries.pid_number LIKE :search OR
       isometries.system LIKE :search OR
       isometries.material LIKE :search OR
       isometries.medium LIKE :search",
      search: term
    )
  }

  private

  def process_isometry_images
    return unless isometry_images.attached?
    return if @processing_images # Add guard to prevent recursive processing

    @processing_images = true # Set processing flag
    begin
      Rails.logger.info "Processing isometry images for isometry #{id}"
      
      isometry_images.each do |image|
        Rails.logger.info "Processing attachment: #{image.filename} (#{image.content_type})"
        
        # Ensure the blob is persisted and analyzed
        image.blob.analyze if !image.blob.analyzed?

        case image.content_type
        when "application/pdf"
          Rails.logger.info "Processing PDF file"
          # Process PDF file
          processed_file = process_pdf_with_qr(image)
          
          # Create new blob and attach it
          new_blob = ActiveStorage::Blob.create_and_upload!(
            io: File.open(processed_file.path),
            filename: image.filename.to_s,
            content_type: "application/pdf"
          )
          
          # Replace the old attachment with the new one
          image.update!(blob: new_blob)
          
          # Clean up
          processed_file.close
          processed_file.unlink
          
          Rails.logger.info "PDF processing completed"
        when /^image\//
          Rails.logger.info "Processing image file"
          # Process image file
          processed_image = add_qr_code_to_image(image)
          
          # Create a temporary file with the processed image
          temp_file = Tempfile.new([ "processed_image", ".png" ])
          processed_image.write(temp_file.path)
          
          # Create new blob and attach it
          new_blob = ActiveStorage::Blob.create_and_upload!(
            io: File.open(temp_file.path),
            filename: image.filename.to_s,
            content_type: image.content_type
          )
          
          # Replace the old attachment with the new one
          image.update!(blob: new_blob)
          
          # Clean up
          temp_file.close
          temp_file.unlink
          
          Rails.logger.info "Image processing completed"
        end
      end
    ensure
      @processing_images = false # Reset processing flag
    end
  end

  def calculate_total_sn
    self.total_sn = (workshop_sn.to_i + assembly_sn.to_i) if workshop_sn.present? || assembly_sn.present?
  end

  def set_on_hold_date
    self.on_hold_date = Time.current if on_hold_status_changed? && on_hold_status.present?
  end
end
