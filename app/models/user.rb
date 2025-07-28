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

  has_many :user_resource_permissions, dependent: :destroy
  has_many :permissions, through: :user_resource_permissions

  has_many :project_users, dependent: :destroy
  has_many :projects, through: :project_users

  has_many :delivery_items, dependent: :nullify
  has_many :final_inspections, dependent: :nullify
  has_many :incoming_deliveries, dependent: :nullify
  has_many :project_logs, dependent: :nullify
  has_many :isometries, dependent: :nullify
  has_many :pre_weldings, dependent: :nullify
  has_many :prefabrications, dependent: :nullify
  has_many :on_sites, dependent: :nullify
  has_many :site_deliveries, dependent: :nullify
  has_many :site_assemblies, dependent: :nullify
  has_many :test_packs, dependent: :nullify
  has_many :transports, dependent: :nullify
  has_many :work_preparations, dependent: :nullify
  has_many :owned_projects, class_name: "Project", foreign_key: "user_id", dependent: :nullify

  def name
    "#{first_name} #{last_name}"
  end

  def active?
    active
  end

  # Check if user has access to sector this is just for menus
  def has_access_to_sector?(sector)
    user_sectors.exists?(sector: sector)
  end

  def has_permission?(action, model_name)
    return true if admin?

    permission = Permission.find_by(code: action)
    return false unless permission

    user_resource_permissions.exists?(
      resource_name: model_name,
      permission: permission
    )
  end

  def has_any_permission?(model_name)
    admin? || user_resource_permissions.exists?(resource_name: model_name)
  end

  # Convenience methods
  def can_create?(model_name)
    has_permission?("create", model_name)
  end

  def can_edit?(model_name)
    has_permission?("edit", model_name)
  end

  def can_delete?(model_name)
    has_permission?("delete", model_name)
  end

  def can_view?(model_name)
    has_permission?("view", model_name) || has_any_permission?(model_name)
  end

  def can_complete?(model_name)
    has_permission?("complete", model_name)
  end

  def has_pending_deliveries?(model_name, project_id)
    model_name.constantize.where(user_id: id, completed: false, project_id: project_id).exists?
  end
end
