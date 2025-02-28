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

  private

  def process_isometry_documents
    return if draft? || !isometry_documents.any?

    isometry_documents.each do |document|
      next unless document.pdf.attached?
    end
  end

  def qr_coordinates
    x = send("qr_#{qr_position}_x")
    y = send("qr_#{qr_position}_y")

    if x.negative?
      x = page_width + x
    end

    if y.negative?
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
    nil if draft?
  end

  def set_default_qr_position
    # No longer setting default QR position
  end
end
