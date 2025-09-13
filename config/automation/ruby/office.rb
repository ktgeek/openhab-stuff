# frozen_string_literal: true

require "color"
require "tasmota"
require "holidays"

stored_led_states = nil

rule "when a zoom meeting is on" do
  changed Zoom_Active_Switch, to: ON

  run do
    if Office_Door_LED_Color.on?
      stored_led_states = store_states Office_Door_LED_Palette, Office_Door_LED_Fade, Office_Door_LED_Scheme,
                                       Office_Door_LED_Speed
    end

    Office_Door_LED_Fade.off
    Office_Door_LED_Scheme.command(Tasmota::Scheme::SINGLE_COLOR)
    Office_Door_LED_Color.command(Color::RED)
  end
end

rule "when a zoom meeting is over" do
  changed Zoom_Active_Switch, to: OFF

  run do
    if stored_led_states
      stored_led_states&.restore_changes
    else
      Office_Door_LED_Color.ensure.off
    end
    stored_led_states = nil
  end
end

rule "turn on the light if someone enters the office" do
  changed Office_Presence_Sensor, to: ON

  run do
    ensure_states do
      Office_Lights_Switch.on
      Office_Monitor_LED.on
      Office_Windows_Switch.on if Holiday_Mode.state == Holidays::CHRISTMAS && Sun_Status.state == "UP"
    end
  end
end

rule "turn off the light when the office is empty" do
  changed Office_Presence_Sensor, to: OFF

  run do
    ensure_states do
      Office_Lights_Switch.off
      Office_Monitor_LED.off
      if Holiday_Mode.state == Holidays::CHRISTMAS && Sun_Status.state == "UP" && Christmas_Lights.off?
        Office_Windows_Switch.off
      end
    end
  end
end

# Fan does 0-3, where 0 is a speed that is not off, but the slider does 0-4, so we need to add 1 to the value.
changed Office_Fan_Speed_Actual do |event|
  Office_Fan_Speed.ensure.update(event.state.to_i.succ)
end

received_command Office_Fan_Speed do |event|
  speed = [event.item.state.to_i - 1, 0].max
  Office_Fan_Speed_Actual.ensure.command(speed)
end
