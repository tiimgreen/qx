class Permission < ApplicationRecord
  has_many :user_resource_permissions, dependent: :destroy
  has_many :users, through: :user_resource_permissions

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
