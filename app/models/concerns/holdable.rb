module Holdable
  extend ActiveSupport::Concern

  included do
    scope :on_hold, -> { where(on_hold: true) }
    scope :not_on_hold, -> { where(on_hold: false) }
  end
end
