# frozen_string_literal: true
require 'openhab'

$LOAD_PATH.unshift(ENV["RUBYLIB"]) if ENV["RUBYLIB"]
require 'wifi_led'

rule "when a zoom meeting is happening" do
  changed Zoom_Active_Switch

  run do |event|
    commands = 0

    if event.state == ON
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
      Office_Door_LED_Power.off unless Office_Door_LED_Power.off?
    end
  end
end
