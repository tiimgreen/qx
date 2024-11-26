class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable


  validates :first_name, :last_name, :phone, :address, :city, presence: true
  # validates :phone, format: { with: /\A\d{8,15}\z/, message: "must be between 8 and 15 digits" }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }

  has_many :user_sectors, dependent: :destroy
  has_many :sectors, through: :user_sectors
  has_many :sector_permissions, through: :user_sectors
  has_many :permissions, through: :sector_permissions



  def name
    "#{first_name} #{last_name}"
  end

  def active?
    active
  end


  # def permissions_for_sector(sector)
  #   sector_permissions
  #     .where(sector: sector)
  #     .includes(:permission)
  #     .map(&:permission)
  # end

  def has_permission?(permission_code, sector)
    sector_permissions.joins(:permission)
      .where(permissions: { code: permission_code })
      .joins(:user_sector)
      .where(user_sectors: { sector_id: sector.id })
      .exists?
  end
end
