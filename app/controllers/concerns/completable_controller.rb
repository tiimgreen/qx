module CompletableController
  extend ActiveSupport::Concern

  private

  def complete_resource(resource, redirect_path, params = {})
    current_time = Time.current

    completion_params = {
      completed: current_time
    }

    merged_params = params.merge(completion_params)

    resource.assign_attributes(merged_params)

    time_data = calculate_total_time(resource, current_time)
    resource.total_time = time_data[:total_minutes]

    if resource.save
      redirect_to redirect_path,
                  notice: t("common.messages.success.completed",
                          model: resource.model_name.human,
                          time: time_data[:formatted])
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def calculate_total_time(resource, end_time = Time.current)
    total_minutes = ((end_time - resource.created_at) / 60.0).round
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
