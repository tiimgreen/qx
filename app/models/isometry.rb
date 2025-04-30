class Isometry < ApplicationRecord
  belongs_to :project
  belongs_to :sector, optional: true
  belongs_to :user, optional: true

  include QrCodeable

  def qr_code_url
    Rails.application.routes.url_helpers.qr_redirect_url(self, host: Rails.application.routes.default_url_options[:host])
  end

  has_many :isometry_material_certificates, dependent: :destroy
  has_many :material_certificates, through: :isometry_material_certificates
  has_many :weldings, dependent: :destroy
  accepts_nested_attributes_for :weldings, allow_destroy: true, reject_if: :all_blank

  has_many :isometry_documents, dependent: :destroy
  accepts_nested_attributes_for :isometry_documents, allow_destroy: true

  has_many_attached :on_hold_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end
  has_one_attached :qr_code do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 100, 100 ]
  end
  has_many_attached :rt_images
  has_many_attached :vt_images
  has_many_attached :pt_images

  has_many :work_preparations, dependent: :destroy
  has_many :test_packs, dependent: :destroy

  has_many :docuvita_documents, as: :documentable, dependent: :destroy

  # Backward compatibility method for the old has_one association
  def work_preparation
    work_preparations.first
  end

  def test_pack
    test_packs.first
  end

  has_one :prefabrication, dependent: :destroy
  has_one :final_inspection, dependent: :destroy
  has_one :transport, dependent: :destroy
  has_one :site_delivery, dependent: :destroy
  has_one :site_assembly, dependent: :destroy
  has_one :on_site, dependent: :destroy
  has_one :test_pack, dependent: :destroy
  has_one :pre_welding, dependent: :destroy
  has_one :incoming_delivery, dependent: :destroy

  after_commit :process_isometry_documents, on: [ :create, :update ]
  after_commit :ensure_qr_code_exists, on: [ :create, :update ]

  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze
  PED_CATEGORIES = [ "N/A", "0", "I", "II", "III", "IV" ].freeze

  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }
  VALID_QR_POSITIONS = %w[top_left top_right bottom_left bottom_right].freeze
  validates :qr_position, inclusion: { in: VALID_QR_POSITIONS, allow_nil: true }

  before_save :log_qr_position_change

  # Validations
  validates :received_date, presence: true
  validates :pid_number, presence: true
  validates :system, presence: true
  validates :pipe_class, presence: true
  validates :material, presence: true
  validates :line_id, presence: true
  validates :revision_number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }, if: :persisted?
  validates :page_number, presence: true
  validates :page_total, presence: true
  validates :medium, presence: true

  # Numeric validations
  validates :pipe_length, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :workshop_sn, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :assembly_sn, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_supports, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_spools, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rt, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :vt2, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :pt2, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Public method for backward compatibility
  def isometry_images
    isometry_documents.map(&:pdf)
  end

  # Public methods for weldings
  def weldings_missing_certificates?
    weldings.exists?(material_certificate_id: nil)
  end

  def weldings_count
    weldings.count
  end

  # Callbacks
  before_save :calculate_total_sn
  before_save :set_on_hold_date

  # Scopes
  scope :active, -> { where(deleted: false).order(line_id: :asc, page_number: :desc) }
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
       isometries.revision_number LIKE :search OR
       isometries.work_package_number LIKE :search OR
       isometries.medium LIKE :search",
      search: term
    )
  }

  # Check if new page can be added
  def can_add_page?
    return false unless revision_last? # Only allow adding pages to latest revision

    # Find all isometries with same line_id and latest revision
    related_isometries = self.class.where(project_id: project_id, line_id: line_id, revision_last: true, deleted: false)

    # Get the first page (page_number = 1) for this line_id and revision
    first_page = related_isometries.find_by(page_number: 1)

    # Only allow adding pages if this is the first page
    return false unless self == first_page

    # Check if we haven't reached the total pages limit
    current_pages_count = related_isometries.count
    current_pages_count < page_total
  end

  def update_weldings(welding_params)
    welding_params.each do |_, welding_attrs|
      if welding_attrs[:id].present?
        # Update existing welding
        welding = weldings.find_by(id: welding_attrs[:id])
        welding&.update(welding_attrs.except(:_destroy))
      elsif !welding_attrs[:_destroy]
        # Create new welding only if not marked for destruction
        weldings.create(welding_attrs)
      end
    end
  end

  # Helper methods to access specific document types
  def docuvita_pdfs
    docuvita_documents.of_type("isometry_pdf")
  end

  def docuvita_rt_images
    docuvita_documents.of_type("rt_image")
  end

  def docuvita_vt_images
    docuvita_documents.of_type("vt_image")
  end

  def docuvita_pt_images
    docuvita_documents.of_type("pt_image")
  end

  def docuvita_on_hold_images
    docuvita_documents.of_type("on_hold_image")
  end

  def docuvita_qr_code
    docuvita_documents.of_type("qr_code").first
  end

  # Method to upload a PDF to Docuvita
  def upload_pdf_to_docuvita(file_io, filename, options = {})
    # Process the PDF with QR code if a position is specified
    if options[:qr_position].present?
      # Create temporary files
      qr_temp_file = Tempfile.new([ "qr", ".png" ])
      pdf_temp_file = Tempfile.new([ "processed", ".pdf" ])
      input_pdf_file = Tempfile.new([ "input", ".pdf" ])

      begin
        # Generate QR code
        current_url = Rails.application.routes.url_helpers.qr_redirect_url(
          isometry_id: id,
          host: Rails.application.routes.default_url_options[:host]
        )
        # Generate QR code image
        qrcode = RQRCode::QRCode.new(current_url, size: 4, level: :l)
        qrcode.as_png(
          bit_depth: 1,
          border_modules: 1,
          color_mode: ChunkyPNG::COLOR_GRAYSCALE,
          color: "black",
          file: qr_temp_file.path,
          fill: "white",
          module_px_size: 3,
          resize_exactly_to: 120
        )

        # Save the original PDF to a temp file
        FileUtils.copy_stream(file_io, input_pdf_file.path)

        # Get PDF dimensions from the first page
        reader = PDF::Reader.new(input_pdf_file.path)
        page = reader.pages.first
        page_width = page.width
        page_height = page.height
        page_rotation = page.attributes[:Rotate] || 0

        # Add QR code to PDF
        Prawn::Document.generate(pdf_temp_file.path,
                               template: input_pdf_file.path,
                               page_size: [ page_width, page_height ]) do |pdf|
          pdf.go_to_page(1)

          # Convert measurements
          mm_to_points = 2.83465
          qr_size = 40
          margin_mm = 15
          margin_pts = margin_mm * mm_to_points

          # Get base coordinates
          base_x, base_y = case options[:qr_position].to_s
          when "bottom_left"
            [ margin_pts - 70, margin_pts - 38 ]
          when "bottom_right"
            [ page_width - margin_pts - qr_size, margin_pts - 38 ]
          when "top_left"
            [ margin_pts + 50, page_height - margin_pts - qr_size + 10 ]
          when "top_right"
            [ page_width - margin_pts - qr_size, page_height - (margin_pts - 12 * mm_to_points) - qr_size ]
          else
            [ margin_pts, margin_pts ]
          end

          # Adjust coordinates based on rotation
          x, y = case page_rotation
          when 90
            # For 90-degree rotation, swap width and height and adjust coordinates
            case options[:qr_position].to_s
            when "bottom_left"
              [ margin_pts - 70, page_width - margin_pts - qr_size ]
            when "bottom_right"
              [ page_height - margin_pts - qr_size, page_width - margin_pts - qr_size ]
            when "top_left"
              [ margin_pts + 50, margin_pts - 38 ]
            when "top_right"
              [ page_height - margin_pts - qr_size, margin_pts - 38 ]
            else
              [ base_x, base_y ]
            end
          else
            [ base_x, base_y ]
          end

          pdf.image qr_temp_file.path,
                   at: [ x, y ],
                   width: qr_size,
                   height: qr_size
        end

        # Create uploader with the processed PDF
        uploader = DocuvitaUploader.new

        # Upload the processed file
        result = uploader.upload_io(
          File.open(pdf_temp_file.path, "rb"),
          filename,
          {
            name: "#{line_id}_#{pid_number}_Rev#{revision_number}_Page#{page_number}",
            description: "Isometry PDF for #{line_id}"
          }.merge(options)
        )

        # Create a record of the uploaded document
        docuvita_documents.create!(
          docuvita_object_id: result[:object_id],
          document_type: "isometry_pdf",
          filename: filename,
          content_type: "application/pdf",
          metadata: {
            qr_position: options[:qr_position],
            qr_url: current_url,
            response: result[:response]
          }
        )
      ensure
        # Clean up temporary files
        qr_temp_file.close
        qr_temp_file.unlink if qr_temp_file && File.exist?(qr_temp_file.path)
        pdf_temp_file.close
        pdf_temp_file.unlink if pdf_temp_file && File.exist?(pdf_temp_file.path)
        input_pdf_file.close
        input_pdf_file.unlink if input_pdf_file && File.exist?(input_pdf_file.path)

        # Reset the file position for potential future use
        file_io.rewind if file_io.respond_to?(:rewind)
      end
    else
      # No QR code needed, upload the original file
      # Create uploader
      uploader = DocuvitaUploader.new

      # Upload the file
      result = uploader.upload_io(
        file_io,
        filename,
        {
          name: "#{line_id}_#{pid_number}_Rev#{revision_number}_Page#{page_number}",
          description: "Isometry PDF for #{line_id}"
        }.merge(options)
      )

      # Create a record of the uploaded document
      docuvita_documents.create!(
        docuvita_object_id: result[:object_id],
        document_type: "isometry_pdf",
        filename: filename,
        content_type: "application/pdf",
        metadata: {
          qr_position: options[:qr_position],
          response: result[:response]
        }
      )
    end
  end

  # Similar methods for other document types
  def upload_image_to_docuvita(file_io, filename, type, options = {})
    # Create uploader
    uploader = DocuvitaUploader.new

    # Upload the file
    result = uploader.upload_io(
      file_io,
      filename,
      {
        name: "#{line_id}_#{type}_#{Time.current.to_i}",
        description: "#{type.upcase} image for #{line_id}"
      }.merge(options)
    )

    # Create a record of the uploaded document
    docuvita_documents.create!(
      docuvita_object_id: result[:object_id],
      document_type: type,
      filename: filename,
      content_type: file_io.content_type,
      metadata: {
        response: result[:response]
      }
    )
  end

  private

  def process_isometry_documents
    return if draft? || !isometry_documents.any?

    isometry_documents.each do |document|
      next unless document.pdf.attached?
    end
  end

  def ensure_qr_code_exists
    debugger
    # Generate QR code if it doesn't exist and we have a valid ID
    return if draft? # Don't generate QR codes for draft isometries
    return if !persisted? # Must be saved first

    # Create a QR code image even if one is already attached (in case URL changed)
    qr_temp_file = Tempfile.new([ "qr", ".png" ])
    begin
      # Generate two URLs - one for show page QR code and one for Docuvita
      show_url = Rails.application.routes.url_helpers.qr_redirect_url(
        self,  # For show page, use self as it works with ActiveStorage
        host: Rails.application.routes.default_url_options[:host]
      )

      docuvita_url = Rails.application.routes.url_helpers.qr_redirect_url(
        id: id,  # For Docuvita, use id as it needs the explicit parameter
        host: Rails.application.routes.default_url_options[:host]
      )

      Rails.logger.info "Generating QR code for URL: #{show_url}"

      # Generate QR code for show page (uses show_url)
      qrcode = RQRCode::QRCode.new(show_url, size: 4, level: :l)

      # Generate PNG with optimized settings
      qrcode.as_png(
        bit_depth: 1,
        border_modules: 1,
        color_mode: ChunkyPNG::COLOR_GRAYSCALE,
        color: "black",
        file: qr_temp_file.path,
        fill: "white",
        module_px_size: 3,
        resize_exactly_to: 120
      )

      # First, attach the QR code to the isometry for display in the show page
      qr_code.attach(
        io: File.open(qr_temp_file.path),
        filename: "qr_code_#{id}.png",
        content_type: "image/png",
        metadata: { qr_url: show_url }
      )

      # Then, if we have a qr_position set, also create a Docuvita document
      if qr_position.present?
        # Generate new QR code for Docuvita (uses docuvita_url)
        qrcode = RQRCode::QRCode.new(docuvita_url, size: 4, level: :l)
        qrcode.as_png(
          bit_depth: 1,
          border_modules: 1,
          color_mode: ChunkyPNG::COLOR_GRAYSCALE,
          color: "black",
          file: qr_temp_file.path,
          fill: "white",
          module_px_size: 3,
          resize_exactly_to: 120
        )

        docuvita_documents.create!(
          docuvita_object_id: upload_qr_to_docuvita(qr_temp_file),
          document_type: "qr_code",
          filename: "qr_code_#{id}.png",
          content_type: "image/png",
          metadata: {
            qr_url: docuvita_url,
            qr_position: qr_position
          }
        )
      end

      Rails.logger.info "QR code successfully attached to isometry #{id}"
    rescue => e
      Rails.logger.error "Error generating QR code: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    ensure
      qr_temp_file.close
      qr_temp_file.unlink if qr_temp_file && File.exist?(qr_temp_file.path)
    end
  end

  def upload_qr_to_docuvita(temp_file)
    uploader = DocuvitaUploader.new
    result = uploader.upload_io(
      File.open(temp_file.path, "rb"),
      "qr_code_#{id}.png",
      {
        name: "QR Code for #{line_id}",
        description: "QR Code for Isometry #{line_id}"
      }
    )
    result[:object_id]
  end

  def calculate_total_sn
    self.total_sn = (workshop_sn.to_i + assembly_sn.to_i) if workshop_sn.present? || assembly_sn.present?
  end

  def set_on_hold_date
    self.on_hold_date = Time.current if on_hold_status_changed? && on_hold_status.present?
  end

  def log_qr_position_change
    nil if draft?
  end

  def set_default_qr_position
    # No longer setting default QR position
  end
end
