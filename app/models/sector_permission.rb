class SectorPermission < ApplicationRecord
  belongs_to :user_sector
  belongs_to :permission

  validates :permission_id, uniqueness: { scope: :user_sector_id }

  def custom_label
    if user_sector&.user && user_sector&.sector && permission
      "#{user_sector.user.first_name} #{user_sector.user.last_name} - #{user_sector.sector.name} - #{permission.name}"
    else
      "Invalid Sector Permission"
    end
  end

  def name
    custom_label
  end

  rails_admin do
    list do
      field :user_sector do
        formatted_value do
          if bindings[:object].user_sector&.user && bindings[:object].user_sector&.sector
            user = bindings[:object].user_sector.user
            sector = bindings[:object].user_sector.sector
            "#{user.first_name} #{user.last_name} - #{sector.name}"
          else
            "Invalid User Sector"
          end
        end
      end
      field :permission do
        formatted_value do
          bindings[:object].permission&.name || "No permission assigned"
        end
      end
      field :created_at
      field :updated_at
    end

    edit do
      field :user_sector
      field :permission
    end
  end
end
