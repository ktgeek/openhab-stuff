# frozen_string_literal: true

require "homeseer"

rule "Garage Doors Change State" do
  changed Large_Garage_Door_Status, Small_Garage_Door_Status

  triggered do |item|
    TV_Notifications << "#{item.label} #{item.state}"

    color = item.state == "closed" ? Homeseer::LedColor::GREEN : Homeseer::LedColor::RED
    leds = items["#{item.name[0..-8]}_Open_LEDs"]
    leds.members.ensure << color
  end
end
