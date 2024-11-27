class QualityInspection < ApplicationRecord
  belongs_to :inspector, class_name: "User"
  has_many :inspection_defects, dependent: :destroy
  has_many_attached :images

  enum inspection_type: {
    dimensional: "dimensional",
    quantity: "quantity",
    visual: "visual"
  }

  validates :inspection_type, presence: true
  validates :inspector, presence: true
  validates :status, presence: true

  accepts_nested_attributes_for :inspection_defects,
                                  allow_destroy: true,
                                  reject_if: :all_blank

  validates :images,
    content_type: { in: [ "image/png", "image/jpeg", "image/jpg" ], message: "must be a PNG or JPEG" },
    size: { less_than: 5.megabytes, message: "should be less than 5MB" },
    limit: { max: 10, message: "You can upload up to 10 images" }

    scope :search_by_term, ->(search_term) {
      return all unless search_term.present?

      term = "%#{search_term}%"
      left_joins(delivery_item: { incoming_delivery: :project })
        .left_joins(:inspector)
        .where(
          "delivery_items.tag_number LIKE :search OR
          delivery_items.batch_number LIKE :search OR
          incoming_deliveries.order_number LIKE :search OR
          projects.name LIKE :search OR
          projects.project_number LIKE :search OR
          users.first_name LIKE :search OR
          users.last_name LIKE :search OR
          quality_inspections.inspection_type LIKE :search OR
          quality_inspections.status LIKE :search",
          search: term
        ).distinct
    }
end
