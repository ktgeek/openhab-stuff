# frozen_string_literal: true

require "color"
require "tasmota"

stored_led_states = nil

rule "when a zoom meeting is on" do
  changed Zoom_Active_Switch, to: ON

  run do
    if Office_Door_LED_Power.on?
      stored_led_states = store_states Office_Door_LED_Palette, Office_Door_LED_Fade, Office_Door_LED_Scheme,
                                       Office_Door_LED_Speed
    end

    Office_Door_LED_Power.ensure.on
    Office_Door_LED_Fade.ensure.off
    Office_Door_LED_Scheme.ensure << Tasmota::Scheme::SINGLE_COLOR
    Office_Door_LED_Color << Color::RED
  end
end

rule "when a zoom meeting is over" do
  changed Zoom_Active_Switch, to: OFF

  run do
    if stored_led_states
      stored_led_states&.restore_changes
      stored_led_states = nil
    else
      Office_Door_LED_Power.ensure.off
    end
  end
end

rule "turn on the light if someone enters the office" do
  changed Office_Presence_Event, to: "enter"

  run do
    Office_Lights_Switch.ensure.on
    Office_Monitor_LED.ensure.on
  end

  only_if { Office_Presence_Sensor.off? }
end

rule "turn off the light when the office is empty" do
  changed Office_Presence_Sensor, to: OFF

  run do
    Office_Lights_Switch.ensure.off
    Office_Monitor_LED.ensure.off
  end
end
