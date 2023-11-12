# frozen_string_literal: true

require "homeseer"

rule "Fake Garage Doors Change State" do
  changed Fake_Large_Garage_Door, Fake_Small_Garage_Door

  run do |event|
    item = event.item

    if event.state.off?
      color = Homeseer::LedColor::GREEN
      state = "closed"
    else
      color = Homeseer::LedColor::RED
      state = "open"
    end

    TV_Notifications << "#{item.label} #{state}"

    leds = items["#{item.name[5..]}_Open_LEDs"]
    leds.members.ensure << color
  end
end
