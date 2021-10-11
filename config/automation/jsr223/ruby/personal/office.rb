# frozen_string_literal: true

require 'openhab'
require 'wifi_led'

stored_led_states = nil

rule "when a zoom meeting is happening" do
  changed Zoom_Active_Switch

  run do |event|
    commands = 0

    if event.state == ON
      if Office_Door_LED_Power.on? && Office_Door_LED_Program != WifiLED::Program::NO_PROGRAM
        stored_led_states = store_states Office_Door_LED_Program
      end

      if Office_Door_LED_Power.off?
        Office_Door_LED_Power.on
        commands += 1
      end

      # The wifi LED controller seems to get really angry if I send too many wifi commands at the same time,
      # so we'll add a delay of 2 seconds per number of commands run
      unless Office_Door_LED_Program == WifiLED::Program::NO_PROGRAM
        after((commands*2).seconds) { Office_Door_LED_Program << WifiLED::Program::NO_PROGRAM }
        commands += 1
      end

      current_color = Office_Door_LED_Color.state
      if [current_color.hue, current_color.saturation, current_color.brightness].join(',') != WifiLED::Color::RED
        after((commands*2).seconds) { Office_Door_LED_Color << WifiLED::Color::RED }
      end
    else
      if stored_led_states
        stored_led_states&.restore_changes
        stored_led_states = nil
      else
        Office_Door_LED_Power.off unless Office_Door_LED_Power.off?
      end
    end
  end
end

rule "Monitor LEDS off at end of day" do
  cron "0 30 22 ? * *"

  run { Office_Monitor_LED.off }
  only_if { Office_Monitor_LED.on? }
end

rule "Monitor LEDS off at end of workday" do
  cron "0 30 17 ? * MON-FRI"

  run { Office_Monitor_LED.off }
  only_if { Office_Monitor_LED.on? }
end

rule "Monitor LEDS on at start of workday" do
  cron "0 30 8 ? * MON-FRI"

  run { Office_Monitor_LED.on }
  only_if { Office_Monitor_LED.off? }
end
