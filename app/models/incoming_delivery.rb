class IncomingDelivery < ApplicationRecord
  belongs_to :project
  has_one_attached :delivery_note
  has_many :delivery_items, dependent: :destroy
  has_many :missing_delivery_items, dependent: :destroy

  validates :delivery_date, presence: true
  validates :order_number, presence: true
  validates :supplier_name, presence: true
end
