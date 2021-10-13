# frozen_string_literal: true

logger.info("Loading script #{__FILE__}")

module Utilities
  # This is a temporary utility until I can write a good ColorItem
  def self.color_to_string(color)
    [color.state.hue, color.state.saturation, color.state.brightness].join(',')
  end
end
