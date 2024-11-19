class Sector < ApplicationRecord
  has_many :user_sectors, dependent: :destroy
  has_many :users, through: :user_sectors
  has_many :sector_permissions, through: :user_sectors

  validates :name, presence: true, uniqueness: true
end
