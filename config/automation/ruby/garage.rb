# frozen_string_literal: true

require "homeseer"

rule "garage doors state" do
  changed Small_Garage_Door_State, Large_Garage_Door_State

  run do |event|
    case event.state
    when "OPENING", "OPEN"
      target_state = ON
      color = Homeseer::LedColor::RED
    when "CLOSING"
      target_state = OFF
      color = Homeseer::LedColor::RED
    else
      target_state = OFF
      color = Homeseer::LedColor::GREEN
    end

    group = event.item.groups.first
    items["#{group.name}_Target_State"].ensure.update(target_state)

    TV_Notifications << "#{group.label} #{event.state}"

    leds = items["#{group.name}_Open_LEDs"]
    leds.members.ensure << color
  end
end

rule "real garage door target" do
  received_command Small_Garage_Door_Target_State, Large_Garage_Door_Target_State

  run do |event|
    name = event.item.groups.first.name
    items["#{name}_State"] << (event.on? ? "OPEN" : "CLOSE")
  end
end
