module SectorModel
  extend ActiveSupport::Concern

  included do
    belongs_to :isometry
    belongs_to :project
    belongs_to :sector

    validates :isometry_id, presence: true
    validates :project_id, presence: true
    validates :sector_id, presence: true

    before_validation :set_project_from_isometry

    private

    def set_project_from_isometry
      self.project = isometry.project if isometry
    end
  end
end
