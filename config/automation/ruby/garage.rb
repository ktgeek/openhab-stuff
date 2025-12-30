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

def awtrix_notifications(message:, info:)
  awtrix = Awtrix3.new(Awtrix_Clock_Display_Power.thing)

  awtrix.set_indicator_color(Awtrix3::INDICATORS[group], info[:awtrix_color], blink: info[:blink_state] == ON)

  awtrix.show_custom_notification(message:, icon: info[:awtrix_icon], color: info[:awtrix_color])
end

rule "garage doors state" do
  changed Small_Garage_Door_State, Large_Garage_Door_State

  run do |event|
    state = event.state.to_s
    info = GARAGE_STATE_INFO[state]

    next unless info

    group = event.item.groups.first

    items["#{group.name}_Target_State"].update(info[:target_state])

    message = "#{group.label} #{state.humanize}"
    TvNotification.notify(message:, avoid_appletv: true)
    awtrix_notifications(message:, info:)

    leds = items["#{group.name}_Open_LEDs"]
    blink_leds = items["#{group.name}_Open_LEDs_Blink"]

    ensure_states do
      leds.members.command(info[:color])
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
