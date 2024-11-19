class Permission < ApplicationRecord
  has_many :sector_permissions, dependent: :destroy
  has_many :user_sectors, through: :sector_permissions

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
