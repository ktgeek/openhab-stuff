# frozen_string_literal: true

require "homeseer"

GARAGE_STATE_INFO = {
  "OPENING" => { target_state: ON, blink_state: ON, color: Homeseer::LedColor::RED },
  "OPEN" => { target_state: ON, blink_state: OFF, color: Homeseer::LedColor::RED },
  "CLOSING" => { target_state: OFF, blink_state: ON, color: Homeseer::LedColor::GREEN },
  "CLOSED" => { target_state: OFF, blink_state: OFF, color: Homeseer::LedColor::GREEN }
}.freeze

rule "garage doors state" do
  changed Small_Garage_Door_State, Large_Garage_Door_State

  run do |event|
    state = event.state
    info = GARAGE_STATE_INFO[state]

    next unless info

    group = event.item.groups.first

    ensure_states do
      items["#{group.name}_Target_State"].update(info[:target_state])

      TV_Notifications.command("#{group.label} #{state}")

      leds = items["#{group.name}_Open_LEDs"]
      leds.members.command(info[:color])

      blink_leds = items["#{group.name}_Open_LEDs_Blink"]
      blink_leds.members.command(info[:blink_state])
    end
  end
end

rule "real garage door target" do
  received_command Small_Garage_Door_Target_State, Large_Garage_Door_Target_State

  run do |event|
    name = event.item.groups.first.name
    items["#{name}_State"].command(event.on? ? "OPEN" : "CLOSE")
  end
end
