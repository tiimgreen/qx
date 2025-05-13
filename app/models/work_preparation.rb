class WorkPreparation < ApplicationRecord
  include SectorModel
  include DocuvitaUploadable

  belongs_to :project
  belongs_to :work_location
  belongs_to :user
  belongs_to :isometry

  has_many :welding_batch_assignments, dependent: :destroy
  has_many :weldings, through: :welding_batch_assignments
  accepts_nested_attributes_for :welding_batch_assignments, allow_destroy: true,
    reject_if: proc { |attributes| attributes["welding_id"].blank? }

  ON_HOLD_STATUSES = [ "N/A", "On Hold" ].freeze
  WORK_PREPARATION_TYPES = [ "cutting_pipes", "small_parts" ].freeze

  has_many_attached :on_hold_images do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
    attachable.variant :medium, resize_to_limit: [ 1200, 1200 ]
  end

  validates :work_package_number, presence: true, uniqueness: { scope: [ :project_id, :isometry_id, :work_preparation_type ] }
  validates :on_hold_status, inclusion: { in: ON_HOLD_STATUSES, allow_nil: true }
  validates :on_hold_comment, length: { maximum: 2000 }
  validates :work_preparation_type, presence: true

  scope :search_by_term, ->(search_term) {
    return all unless search_term.present?

    term = "%#{search_term}%"

    left_joins(:work_location, :user, :isometry, weldings: :isometry)
    .where(
      "work_locations.location_type LIKE :search OR
       work_locations.name LIKE :search OR
       work_locations.key LIKE :search OR
       users.first_name LIKE :search OR
       users.email LIKE :search OR
       work_preparations.work_package_number LIKE :search OR
       work_preparations.on_hold_status LIKE :search OR
       work_preparations.on_hold_comment LIKE :search OR
       isometries.line_id LIKE :search OR
       isometries.page_number LIKE :search OR
       isometries.revision_number LIKE :search OR
       isometries.pid_number LIKE :search",
      search: term
    )
    .distinct
  }

  # Helper methods for Docuvita document access
  # def on_hold_images
  #   docuvita_documents.where(documentable_type: "WorkPreparation", document_sub_type: "on_hold_image")
  # end
  # alias_method :on_hold_documents, :on_hold_images

  def on_hold?
    on_hold_status == "On Hold"
  end

  def self.in_progress_for?(isometry)
    isometry.work_preparations.any? { |wp| wp.completed.nil? }
  end

  def self.completed_for?(isometry)
    completed_count = isometry.work_preparations.count { |wp| wp.completed.present? }
    completed_count == WORK_PREPARATION_TYPES.size
  end

  def self.status_for(isometry)
    work_preparations = isometry.work_preparations
    return :not_started if work_preparations.empty?

    completed_count = work_preparations.count { |wp| wp.completed.present? }

    if completed_count == WORK_PREPARATION_TYPES.size
      :completed
    elsif completed_count > 0 || work_preparations.any?
      :in_progress
    else
      :not_started
    end
  end

  def self.status_details_for(isometry)
    WORK_PREPARATION_TYPES.each_with_object({}) do |type, hash|
      tp = isometry.work_preparations.find_by(work_preparation_type: type)
      hash[type] = if tp&.completed.present?
                    :completed
      elsif tp
                    :in_progress
      else
                    :not_started
      end
    end
  end

  private

  # Validation is now handled in DocuvitaUploadable concern
  # def validate_image_format
  #   return unless on_hold_images.attached?
  #
  #   on_hold_images.each do |image|
  #     unless image.content_type.in?(%w[image/jpeg image/png])
  #       errors.add(:on_hold_images, :invalid_format)
  #       image.purge
  #     end
  #
  #     if image.byte_size > 5.megabytes
  #       errors.add(:on_hold_images, :too_large)
  #       image.purge
  #     end
  #   end
  # end
end
