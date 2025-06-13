module LockedByArchivedProject
  extend ActiveSupport::Concern

  included do
    validate :project_not_archived
    before_destroy { throw :abort if project&.archived? }
  end

  private
  def project_not_archived
    errors.add(:base, I18n.t("common.errors.archived")) if project&.archived?
  end
end
