class MaterialCertificate < ApplicationRecord
  belongs_to :project
  has_one_attached :certificate_file

  validates :certificate_number, presence: true, uniqueness: true
  validates :batch_number, presence: true
  validates :issue_date, presence: true
end
