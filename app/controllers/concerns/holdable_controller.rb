module HoldableController
  extend ActiveSupport::Concern

  private

  def process_hold_attributes(attributes, model = nil)
    return attributes unless attributes.has_key?(:on_hold)

    # Convert to boolean more explicitly
    new_on_hold = attributes[:on_hold].to_s == "1" || attributes[:on_hold].to_s.downcase == "true"

    # Create a new hash to avoid modifying the original params
    processed_attributes = attributes.dup

    if new_on_hold
      # If it's a new record or switching from not on hold to on hold
      if model.nil? || !model.on_hold?
        processed_attributes[:on_hold_date] = Time.current
      end
    else
      # If turning off hold, always clear the fields
      processed_attributes[:on_hold] = false
      processed_attributes[:on_hold_date] = nil
      processed_attributes[:on_hold_reason] = nil
    end

    processed_attributes
  end

  def holdable_params
    %i[on_hold on_hold_reason on_hold_date]
  end
end
