class QualityInspection < ApplicationRecord
  belongs_to :delivery_item
  has_many :inspection_defects, dependent: :destroy
  has_many_attached :images

  enum inspection_type: {
    dimensional: "dimensional",
    quantity: "quantity",
    visual: "visual"
  }

  validates :inspection_type, presence: true
  validates :inspector_name, presence: true
  validates :status, presence: true

  accepts_nested_attributes_for :inspection_defects,
                                  allow_destroy: true,
                                  reject_if: :all_blank

  validates :images,
    content_type: { in: [ "image/png", "image/jpeg", "image/jpg" ], message: "must be a PNG or JPEG" },
    size: { less_than: 5.megabytes, message: "should be less than 5MB" },
    limit: { max: 10, message: "You can upload up to 10 images" }
end
