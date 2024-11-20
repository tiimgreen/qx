class DeliveryItem < ApplicationRecord
  belongs_to :incoming_delivery
  has_many :quality_inspections, dependent: :destroy
  has_many :roughness_measurements, dependent: :destroy
  has_many :material_certificate_items, dependent: :destroy
  has_many :material_certificates, through: :material_certificate_items
  has_one :roughness_measurement

  validates :tag_number, presence: true, uniqueness: { scope: :incoming_delivery_id }
  validates :batch_number, presence: true
  validates :quantity_received, presence: true, numericality: { greater_than: 0 }

  serialize :specifications, coder: JSON
end
