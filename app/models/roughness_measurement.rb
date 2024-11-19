class RoughnessMeasurement < ApplicationRecord
  belongs_to :delivery_item
  has_one_attached :measurement_report

  validates :measurement_date, presence: true
  validates :measured_value, presence: true, numericality: true
end
