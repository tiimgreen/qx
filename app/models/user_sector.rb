class UserSector < ApplicationRecord
  belongs_to :user
  belongs_to :sector
  has_many :sector_permissions, dependent: :destroy
  has_many :permissions, through: :sector_permissions

  validates :user_id, uniqueness: { scope: :sector_id }

  def custom_label
    if user && sector
      "#{user.first_name} #{user.last_name} - #{sector.name}"
    else
      "Invalid User Sector"
    end
  end

  def name
    custom_label
  end

  rails_admin do
    list do
      field :user do
        formatted_value do
          user = bindings[:object].user
          user ? "#{user.first_name} #{user.last_name}" : "No user assigned"
        end
      end
      field :sector do
        formatted_value do
          bindings[:object].sector&.name || "No sector assigned"
        end
      end
      field :permissions
      field :created_at
      field :updated_at
    end

    edit do
      field :user
      field :sector
      field :sector_permissions
    end
  end
end