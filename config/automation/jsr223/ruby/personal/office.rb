# frozen_string_literal: true

require 'openhab'
require 'wifi_led'
require 'utilities'

stored_led_states = nil

rule "when a zoom meeting is on" do
  changed Zoom_Active_Switch, to: ON

  run do
    stored_led_states = store_states Office_Door_LED_Program if Office_Door_LED_Power.on? && Office_Door_LED_Program != WifiLED::Program::NO_PROGRAM

    commands = []

    commands << [Office_Door_LED_Power, ON] if Office_Door_LED_Power.off?

    commands << [Office_Door_LED_Program, WifiLED::Program::NO_PROGRAM] unless Office_Door_LED_Program == WifiLED::Program::NO_PROGRAM

    commands << [Office_Door_LED_Color, WifiLED::Color::RED] if Utilities::color_to_string(Office_Door_LED_Color) != WifiLED::Color::RED

    # The wifi LED controller seems to get really angry if I send too many wifi commands at the same time,
    # so we'll add a delay of 2 seconds per number of commands run
    last_command = commands.last
    commands.each do |c|
      c[0] << c[1]
      sleep 2 unless c == last_command
    end
  end
end

rule "when a zoom meeting is over" do
  changed Zoom_Active_Switch, to: OFF

  run do
    if stored_led_states
        stored_led_states&.restore_changes
        stored_led_states = nil
    else
      Office_Door_LED_Power.off unless Office_Door_LED_Power.off?
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
