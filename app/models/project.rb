class Project < ApplicationRecord
  has_many :incoming_deliveries
  has_many :material_certificates
  has_many :delivery_items, through: :incoming_deliveries

  validates :project_number, presence: true, uniqueness: true
  validates :name, presence: true
end
