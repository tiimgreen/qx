class Guest < ApplicationRecord
  # Include only necessary devise modules
  devise :database_authenticatable,
         :rememberable, :validatable

  belongs_to :project

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :active, inclusion: { in: [ true, false ] }

  def full_name
    "#{first_name} #{last_name}"
  end
end
