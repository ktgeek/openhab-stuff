# frozen_string_literal: true

require "forwardable"

# Actions for an AWTRIX NG clock (the `mqtt.awtrixng` binding). Same public interface as Awtrix3, but the binding takes
# "#RRGGBB" strings and a single params map for notifications.
class AwtrixNg
  extend Forwardable

  def_delegators :@actions, :activate_indicator, :blink_indicator, :deactivate_indicator, :dismiss_named_notifications

  def self.actions(thing)
    thing.actions("mqtt.awtrixlight")
  end

  def self.bedroom_clock
    @bedroom_clock ||= new(Bedroom_AwtrixClock_Power.thing)
  end

  def self.office_clock
    @office_clock ||= new(Office_AwtrixClock_Power.thing)
  end

  def initialize(thing)
    @actions = AwtrixNg.actions(thing)
  end

  def show_custom_notification(message:, icon:, case_insensitive: false, color: nil, name: nil)
    # The binding rejects the whole notification if it contains a key it doesn't know
    params = { "text" => message, "icon" => icon, "wakeup" => true, "stack" => true, "textCase" => "asTyped" }
    params.delete("textCase") if case_insensitive
    params["textColor"] = java_color(color) if color
    params["name"] = name if name

    @actions.show_custom_notification(params)
  end

  # Set the color of an indicator, or deactivate it if color is nil
  def set_indicator_color(indicator, color, blink: false)
    if color
      if blink
        blink_indicator(indicator, java_color(color), 500)
      else
        activate_indicator(indicator, java_color(color))
      end
    else
      deactivate_indicator(indicator)
    end
  end

  private

  def java_color(color)
    color.to_java(Java::int)
  end
end
