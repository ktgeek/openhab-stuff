# frozen_string_literal: true

require "forwardable"

class Awtrix3
  extend Forwardable

  def_delegators :@actions, :activate_indicator, :blink_indicator, :deactivate_indicator

  def self.actions(thing)
    thing.actions("mqtt.awtrixlight")
  end

  def self.office_clock
    @office_clock ||= new(Office_AwtrixClock_Power.thing)
  end

  def initialize(thing)
    @actions = Awtrix3.actions(thing)
  end

  def show_custom_notification(message:, icon:, color: nil)
    params = {
      "text" => message,
      "icon" => icon
    }
    params["color"] = color.to_java(Java::int) if color

    @actions.show_custom_notification(params, false, true, true, "", "", false)
  end

  # Set the color of an indicator, or deactivate it if color is nil
  def set_indicator_color(indicator, color, blink: false)
    if color
      java_color = color.to_java(Java::int)
      if blink
        @actions.blink_indicator(indicator, java_color, 500)
      else
        @actions.activate_indicator(indicator, java_color)
      end
    else
      @actions.deactivate_indicator(indicator)
    end
  end
end
