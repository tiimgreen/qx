class IncomingDelivery < ApplicationRecord
  belongs_to :project
  has_many_attached :delivery_notes
  has_many :delivery_items, dependent: :destroy
  has_many :missing_delivery_items, dependent: :destroy
  has_many :material_certificates, through: :delivery_items

  validates :delivery_date, presence: true
  validates :order_number, presence: true, uniqueness: true
  validates :supplier_name, presence: true
end
