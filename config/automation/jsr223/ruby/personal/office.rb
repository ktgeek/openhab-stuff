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

rule "Monitor LEDs off at end of day" do
  cron "0 30 22 ? * *"

  run { Office_Monitor_LED.off }
  only_if { Office_Monitor_LED.on? }
end

rule "Monitor LEDs off at end of workday" do
  cron "0 30 17 ? * MON-FRI"

  run { Office_Monitor_LED.off }
  only_if { Office_Monitor_LED.on? }
end

rule "Monitor LEDs on at start of workday" do
  cron "0 30 8 ? * MON-FRI"

  run { Office_Monitor_LED.on }
  only_if { Office_Monitor_LED.off? }
end
