module Holdable
  extend ActiveSupport::Concern

  included do
    validates :on_hold_date, presence: true, if: :on_hold
    validates :on_hold_reason, presence: true, if: :on_hold

    before_validation :cleanup_hold_attributes
  end

  private

  def cleanup_hold_attributes
    if on_hold
      self.on_hold_date ||= Time.current
    else
      self.on_hold_date = nil
      self.on_hold_reason = nil
    end
  end
end