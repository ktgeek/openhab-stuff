# frozen_string_literal: true

require "zigbee"

rule "when family room lights turn on/off, turn on/off LEDs" do
  changed FamilyRoom_Lights_Switch

  run { |event| FamilyRoom_LED_Power.ensure.command(event.state) }
end

channel(Zigbee::SINGLE_TAP, thing: Family_Room_Fan_Button_Battery.thing) { FamilyRoom_Lights_Switch.toggle }

channel(Zigbee::DOUBLE_TAP, thing: Family_Room_Fan_Button_Battery.thing) { Family_Room_Ceiling_Fan_Light_Power.toggle }

channel(Zigbee::HOLD, thing: Family_Room_Fan_Button_Battery.thing) { Family_Room_Ceiling_Fan_Fan_Power.toggle }
