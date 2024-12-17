class Isometry < ApplicationRecord
  belongs_to :project
  belongs_to :sector, optional: true
  belongs_to :user, optional: true

  include QrCodeable

  has_many :isometry_material_certificates, dependent: :destroy
  has_many :material_certificates, through: :isometry_material_certificates
  has_many :weldings, dependent: :destroy
  accepts_nested_attributes_for :weldings, allow_destroy: true

  has_many :isometry_documents, dependent: :destroy
  accepts_nested_attributes_for :isometry_documents, allow_destroy: true

  has_many_attached :on_hold_images
  has_many_attached :rt_images
  has_many_attached :vt_images
  has_many_attached :pt_images

  after_commit :process_isometry_documents, on: [ :create, :update ]

  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze
  PED_CATEGORIES = [ "N/A", "I", "II", "III", "IV" ].freeze

  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }
  VALID_QR_POSITIONS = %w[top_left top_right bottom_left bottom_right].freeze
  validates :qr_position, inclusion: { in: VALID_QR_POSITIONS }
  after_initialize :set_default_qr_position, if: :new_record?

  before_save :log_qr_position_change

  # Validations
  validates :received_date, presence: true
  validates :pid_number, presence: true
  validates :system, presence: true
  validates :pipe_class, presence: true
  validates :material, presence: true
  validates :line_id, presence: true
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
       isometries.medium LIKE :search",
      search: term
    )
  }

  # Check if new page can be added
  def can_add_page?
    return false unless revision_last? # Only allow adding pages to latest revision

    # Find all isometries with same line_id and latest revision
    related_isometries = self.class.where(line_id: line_id, revision_last: true, deleted: false)

    # Get the first page (page_number = 1) for this line_id and revision
    first_page = related_isometries.find_by(page_number: 1)

    # Only allow adding pages if this is the first page
    return false unless self == first_page

    # Check if we haven't reached the total pages limit
    current_pages_count = related_isometries.count
    current_pages_count < page_total
  end

  private

  def process_isometry_documents
    return unless isometry_documents.any?

    isometry_documents.each do |document|
      next unless document.pdf.attached?

      Rails.logger.info "Processing isometry document: #{document.pdf.filename} (#{document.pdf.content_type})"

      # The actual processing is now handled by the IsometryDocument model
      # through its after_commit callback
    end
  end

  def qr_coordinates
    x = send("qr_#{qr_position}_x")
    y = send("qr_#{qr_position}_y")

    if x.negative?
      # Convert negative x (from right edge) to positive x based on page width
      x = page_width + x
    end

    if y.negative?
      # Convert negative y (from bottom edge) to positive y based on page height
      y = page_height + y
    end

    [ x, y ]
  end

  def calculate_total_sn
    self.total_sn = (workshop_sn.to_i + assembly_sn.to_i) if workshop_sn.present? || assembly_sn.present?
  end

  def set_on_hold_date
    self.on_hold_date = Time.current if on_hold_status_changed? && on_hold_status.present?
  end

  def log_qr_position_change
    Rails.logger.info "========== QR Position Debug =========="
    Rails.logger.info "Current QR Position: #{qr_position.inspect}"
    Rails.logger.info "QR Position in database: #{qr_position_was.inspect}"
    Rails.logger.info "QR Position changed?: #{qr_position_changed?}"
    Rails.logger.info "All changes: #{changes.inspect}"
    Rails.logger.info "Valid positions: #{VALID_QR_POSITIONS.inspect}"
    Rails.logger.info "====================================="
  end

  def set_default_qr_position
    Rails.logger.info "Setting default QR position"
    Rails.logger.info "Current position before default: #{qr_position.inspect}"
    self.qr_position = "top_right" if qr_position.blank?
    Rails.logger.info "Position after default: #{qr_position.inspect}"
  end
end
