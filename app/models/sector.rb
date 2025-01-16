class Sector < ApplicationRecord
  has_many :user_sectors, dependent: :destroy
  has_many :users, through: :user_sectors

  QR_SECTOR_MODELS = [
    "work_preparation",
    "prefabrication",
    "pre_welding",
    "final_inspection",
    "transport",
    "site_delivery",
    "site_assembly",
    "on_site",
    "test_pack",
    "isometry"
  ].freeze

  validates :key, presence: true, uniqueness: true

  def name
    I18n.t("sectors.#{key}")
  end

  def description
    I18n.t("sectors.#{key}_description", default: "")
  end
end
