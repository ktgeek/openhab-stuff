# frozen_string_literal: true
require 'openhab'
require 'homeseer'

rule "Garage Doors Change State" do
  changed [Large_Garage_Door_Status, Small_Garage_Door_Status]

  triggered do |item|
    underscore_label = item.label.tr(" ", "_")
    leds = items["#{underscore_label}_Open_LEDs"]

    color, status_text = item != "closed" ? [Homeseer::Led_Color::RED, "opened"] : [Homeseer::Led_Color::GREEN, "closed"]

    leds.each { |i| i << color unless i == color }
    TV_Notifications << "#{item.label} #{status_text}"
  end
end
