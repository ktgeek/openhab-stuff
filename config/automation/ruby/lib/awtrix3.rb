# frozen_string_literal: true

require "forwardable"

class Awtrix3
  extend Forwardable

  def_delegators :@actions, :activate_indicator, :blink_indicator, :deactivate_indicator

  INDICATORS = {
    ::Large_Garage_Door => 1,
    ::Small_Garage_Door => 2,
    ::House_Perimeter_Contacts => 3
  }.freeze

  module Color
    RED = [255, 0, 0].to_java(Java::int).freeze
    GREEN = [0, 255, 0].to_java(Java::int).freeze
    BLUE = [0, 0, 255].to_java(Java::int).freeze
    YELLOW = [255, 255, 0].to_java(Java::int).freeze
    WHITE = [255, 255, 255].to_java(Java::int).freeze
  end

  def self.actions(thing)
    thing.actions("mqtt.awtrixlight")
  end

  def initialize(thing)
    @actions = Awtrix3.actions(thing)
  end

  def show_custom_notification(message:, icon:, color: nil)
    params = {
      "text" => message,
      "icon" => icon
    }
    params["color"] = color if color

    @actions.show_custom_notification(params, false, true, true, "", "", false)
  end

  # Set the color of an indicator, or deactivate it if color is nil
  def set_indicator_color(indicator, color, blink: false)
    if color
      if blink
        @actions.blink_indicator(indicator, color, 500)
      else
        @actions.activate_indicator(indicator, color)
      end
    else
      @actions.deactivate_indicator(indicator)
    end
  end
end
