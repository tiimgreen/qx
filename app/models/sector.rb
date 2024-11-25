class Sector < ApplicationRecord
  has_many :user_sectors, dependent: :destroy
  has_many :users, through: :user_sectors
  has_many :sector_permissions, through: :user_sectors

  validates :key, presence: true, uniqueness: true

  def name
    I18n.t("sectors.#{key}")
  end

  def description
    I18n.t("sectors.#{key}_description", default: '')
  end
end
