class ProjectSector < ApplicationRecord
  belongs_to :project
  validates :sector, presence: true
end
