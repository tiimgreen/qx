class Guest < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  belongs_to :project
  
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :active, inclusion: { in: [true, false] }
  
  def full_name
    "#{first_name} #{last_name}"
  end
end
