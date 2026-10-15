# frozen_string_literal: true

# Actions for an AWTRIX NG clock (the `mqtt.awtrixng` binding). Same public interface as Awtrix3, but the binding takes
# "#RRGGBB" strings and a single params map for notifications.
class AwtrixNg
  def self.actions(thing)
    thing.actions("mqtt.awtrixng")
  end

  def self.bedroom_clock
    @bedroom_clock ||= new(Bedroom_AwtrixClock_Power.thing)
  end

  def initialize(thing)
    @actions = AwtrixNg.actions(thing)
  end

  def show_custom_notification(message:, icon:, color: nil)
    # The binding rejects the whole notification if it contains a key it doesn't know
    params = { "text" => message, "icon" => icon, "wakeup" => true, "stack" => true }
    params["textColor"] = hex(color) if color

    @actions.show_custom_notification(params)
  end

  # Set the color of an indicator, or deactivate it if color is nil
  def set_indicator_color(indicator, color, blink: false)
    if color
      if blink
        @actions.blink_indicator(indicator, hex(color), 500)
      else
        @actions.activate_indicator(indicator, hex(color))
      end
    else
      @actions.deactivate_indicator(indicator)
    end
  end

  private

  def hex(color)
    format("#%02X%02X%02X", *color)
  end
end
