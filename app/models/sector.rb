class Sector < ApplicationRecord
  has_many :user_sectors, dependent: :destroy
  has_many :users, through: :user_sectors

  QR_SECTOR_MODELS = [
    "final_inspection",
    "isometry",
    "on_site",
    "pre_welding",
    "prefabrication",
    "site_assembly",
    "site_delivery",
    "test_pack",
    "transport",
    "work_preparation"
  ].freeze

  validates :key, presence: true, uniqueness: true

  def name
    I18n.t("sectors.#{key}")
  end

  def description
    I18n.t("sectors.#{key}_description", default: "")
  end
end
