class Project < ApplicationRecord
  has_many :incoming_deliveries
  has_many :material_certificates

  validates :project_number, presence: true, uniqueness: true
  validates :name, presence: true
end
