# frozen_string_literal: true

require "homeseer"
require "tv_notification"
require "awtrix3"

GARAGE_STATE_INFO = {
  "OPENING" => { target_state: ON, blink_state: ON, color: Homeseer::LedColor::RED,
                 awtrix_color: Awtrix3::Color::RED, awtrix_icon: "garagedooropen" },
  "OPEN" => { target_state: ON, blink_state: OFF, color: Homeseer::LedColor::RED,
              awtrix_color: Awtrix3::Color::RED, awtrix_icon: "garageopened" },
  "CLOSING" => { target_state: OFF, blink_state: ON, color: Homeseer::LedColor::GREEN,
                 awtrix_color: Awtrix3::Color::GREEN, awtrix_icon: "garagedoorclose" },
  "CLOSED" => { target_state: OFF, blink_state: OFF, color: Homeseer::LedColor::GREEN,
                awtrix_color: nil, awtrix_icon: "garageclosed" }
}.freeze

def awtrix_notifications(message:, info:, item:)
  awtrix = Awtrix3.office_clock

  awtrix.set_indicator_color(Awtrix3::INDICATORS[item], info[:awtrix_color], blink: info[:blink_state] == ON)

  awtrix.show_custom_notification(message:, icon: info[:awtrix_icon], color: info[:awtrix_color])
end

changed(Garage_SmallDoor_Current_Operation, Garage_LargeDoor_Current_Operation) do |event|
  group_name = event.item.groups.first.name
  position, dstate, dstate_binary = %w[Position State State_Binary].map { |n| items["#{group_name}_#{n}"] }

  case event.state
  when "IDLE"
    closed = position.down?
    dstate.update(closed ? "CLOSED" : "OPEN")
    dstate_binary.update(closed ? OFF : ON)
  when /^IS_/
    dstate.update(event.state.delete_prefix("IS_"))
  end
end

changed(Garage_SmallDoor_State, Garage_LargeDoor_State) do |event|
  state = event.state.to_s
  info = GARAGE_STATE_INFO[state]

  next unless info

  group = event.item.groups.first

  items["#{group.name}_Target_State"].update(info[:target_state])

  message = "#{group.label} #{state.humanize}"
  TvNotification.notify(message:, avoid_appletv: true)
  awtrix_notifications(message:, info:, item: group)

  leds = items["#{group.name}_Open_LEDs"]
  blink_leds = items["#{group.name}_Open_LEDs_Blink"]

  ensure_states do
    leds.members.command(info[:color])
    blink_leds.members.command(info[:blink_state])
  end
end

received_command(Garage_SmallDoor_Target_State, Garage_LargeDoor_Target_State) do |event|
  name = event.item.groups.first.name
  items["#{name}_Position"].command(event.on? ? UP : DOWN)
end
