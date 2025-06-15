class ProjectSector < ApplicationRecord
  include LockedByArchivedProject

  belongs_to :project
  belongs_to :sector
  validates :sector, presence: true
end
