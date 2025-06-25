module LockedByArchivedProject
  extend ActiveSupport::Concern

  included do
    validate :project_not_archived
    before_destroy { throw :abort if respond_to?(:project) && project&.archived? }
  end

  private
  def project_not_archived
    return unless respond_to?(:project) && project.present?

    errors.add(:base, I18n.t("common.errors.archived")) if project.archived?
  end
end
