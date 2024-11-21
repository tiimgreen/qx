class RoughnessMeasurement < ApplicationRecord
  belongs_to :delivery_item
  has_many_attached :measurement_reports

  validates :measurement_date, presence: true
  validates :measured_value, presence: true, numericality: true
end
