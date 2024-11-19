class QualityInspection < ApplicationRecord
  belongs_to :delivery_item
  has_many :inspection_defects, dependent: :destroy

  enum inspection_type: {
    dimensional: "dimensional",
    quantity: "quantity",
    visual: "visual"
  }

  validates :inspection_type, presence: true
  validates :inspector_name, presence: true
  validates :status, presence: true
end
