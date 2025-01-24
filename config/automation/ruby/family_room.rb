# frozen_string_literal: true

require "zigbee"

rule "when family room lights turn on/off, turn on/off LEDs" do
  changed FamilyRoom_Lights_Switch

  run { |event| FamilyRoom_LED_Power.ensure.command(event.state) }
end

BUTTON_ACTION = "mqtt:topic:26bcbec1ee:family_room_fan_button:action"
channel(BUTTON_ACTION, triggered: Zigbee::SINGLE_TAP) { FamilyRoom_Lights_Switch.toggle }

channel(BUTTON_ACTION, triggered: Zigbee::DOUBLE_TAP) { Family_Room_Ceiling_Fan_Light_Power.toggle }

channel(BUTTON_ACTION, triggered: Zigbee::HOLD) { Family_Room_Ceiling_Fan_Fan_Power.toggle }
