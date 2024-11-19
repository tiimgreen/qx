class MissingDeliveryItem < ApplicationRecord
  belongs_to :incoming_delivery

  validates :expected_quantity, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
  validates :order_line_reference, uniqueness: { scope: :incoming_delivery_id, allow_blank: true }
end
