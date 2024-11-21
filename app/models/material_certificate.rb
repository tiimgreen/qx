class MaterialCertificate < ApplicationRecord
  belongs_to :project
  has_one_attached :certificate_file
  has_many :material_certificate_items, dependent: :destroy
  has_many :delivery_items, through: :material_certificate_items

  validates :certificate_number, presence: true, uniqueness: true
  validates :batch_number, presence: true
  validates :issue_date, presence: true

  scope :pending, -> { where(status: "pending") }
end
