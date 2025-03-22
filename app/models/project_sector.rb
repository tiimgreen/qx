class ProjectSector < ApplicationRecord
  belongs_to :project
  belongs_to :sector
  validates :sector, presence: true
end
