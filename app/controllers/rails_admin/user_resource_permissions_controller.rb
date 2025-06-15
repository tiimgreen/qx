module RailsAdmin
  class UserResourcePermissionsController < RailsAdmin::ApplicationController
    def current_permissions
      user_id = params[:user_id]
      resource_name = params[:resource_name]

      permissions = UserResourcePermission
        .includes(:permission)
        .where(user_id: user_id, resource_name: resource_name)

      current_permissions = permissions.map do |p|
        "• #{p.permission.name}"
      end

      permission_data = {
        permission_ids: permissions.pluck(:permission_id),
        current_permissions: current_permissions.any? ? current_permissions.join("<br>") : nil
      }

      render json: permission_data
    end
  end
end
