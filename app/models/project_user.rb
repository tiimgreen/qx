class ProjectUser < ApplicationRecord
  include LockedByArchivedProject

  belongs_to :project
  belongs_to :user
end
