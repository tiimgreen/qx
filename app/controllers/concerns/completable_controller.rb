module CompletableController
  extend ActiveSupport::Concern

  private

  def complete_resource(resource, redirect_path, params)
    resource.assign_attributes(params)
    resource.completed = true
    time_data = calculate_total_time(resource)
    resource.total_time = time_data[:total_minutes]

    if resource.save
      redirect_to redirect_path,
                  notice: t("common.messages.completed",
                          model: resource.model_name.human,
                          time: time_data[:formatted])
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def calculate_total_time(resource)
    total_minutes = ((Time.current - resource.created_at) / 60.0).round
    hours = (total_minutes / 60).floor
    minutes = total_minutes % 60
    {
      formatted: format("%02d:%02d", hours, minutes),
      total_minutes: total_minutes
    }
  end

  def completable_params
    %i[completed total_time]
  end
end
