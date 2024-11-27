class UserSector < ApplicationRecord
  belongs_to :user
  belongs_to :sector

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


end
