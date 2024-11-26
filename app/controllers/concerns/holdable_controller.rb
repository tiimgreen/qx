# app/controllers/concerns/holdable_controller.rb
module HoldableController
  extend ActiveSupport::Concern

  private

  def process_hold_attributes(attributes)
    attributes = attributes.to_h if attributes.respond_to?(:to_h)

    Rails.logger.debug "Original attributes: #{attributes.inspect}"
    return attributes unless attributes && attributes.key?(:on_hold)

    # Convert to boolean more explicitly and convert string keys to symbols
    processed_attributes = attributes.deep_symbolize_keys
    new_on_hold = processed_attributes[:on_hold].to_s == "1" || processed_attributes[:on_hold].to_s.downcase == "true"

    Rails.logger.debug "Processing hold status: #{new_on_hold}"

    if new_on_hold
      processed_attributes[:on_hold] = true
      processed_attributes[:on_hold_date] = Time.current
      processed_attributes[:on_hold_reason] = processed_attributes[:on_hold_reason].presence
    else
      processed_attributes[:on_hold] = false
      processed_attributes[:on_hold_date] = nil
      processed_attributes[:on_hold_reason] = nil
    end

    Rails.logger.debug "Processed attributes: #{processed_attributes.inspect}"
    processed_attributes
  end

  def holdable_params
    %i[on_hold on_hold_reason on_hold_date]
  end
end