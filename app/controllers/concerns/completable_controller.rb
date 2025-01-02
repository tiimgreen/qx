module CompletableController
  extend ActiveSupport::Concern

  private

  def complete_resource(resource, redirect_path, params = {})
    current_time = Time.current
    Rails.logger.debug "CompletableController#complete_resource"
    Rails.logger.debug "Current time: #{current_time}"
    Rails.logger.debug "Original params: #{params.inspect}"
    
    # Set completion time and active status
    completion_params = {
      completed: current_time,
      active: false
    }
    Rails.logger.debug "Completion params: #{completion_params.inspect}"
    
    # Merge and assign attributes
    merged_params = params.merge(completion_params)
    Rails.logger.debug "Merged params: #{merged_params.inspect}"
    
    resource.assign_attributes(merged_params)
    Rails.logger.debug "Resource after assign: completed=#{resource.completed}, active=#{resource.active}"
    
    # Calculate and set total time
    time_data = calculate_total_time(resource, current_time)
    resource.total_time = time_data[:total_minutes]
    Rails.logger.debug "Total time: #{time_data.inspect}"
    Rails.logger.debug "Resource before save: #{resource.attributes.inspect}"

    if resource.save
      Rails.logger.debug "Save successful!"
      redirect_to redirect_path,
                  notice: t("common.messages.completed",
                          model: resource.model_name.human,
                          time: time_data[:formatted])
    else
      Rails.logger.debug "Save failed! Errors: #{resource.errors.full_messages}"
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
