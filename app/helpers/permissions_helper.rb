module PermissionsHelper
  def can_view?(sector)
    can_perform_action?(sector, "view")
  end

  def can_create?(sector)
    can_perform_action?(sector, "create")
  end

  def can_edit?(sector)
    can_perform_action?(sector, "edit")
  end

  def can_delete?(sector)
    can_perform_action?(sector, "delete")
  end

  private

  def can_perform_action?(sector, action_code)
    current_user.sector_permissions.exists?(
      sector: sector,
      permission: Permission.find_by(code: action_code)
    )
  end
end
