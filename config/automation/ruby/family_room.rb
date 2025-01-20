# frozen_string_literal: true

rule "when family room lights turn on/off, turn on/off LEDs" do
  changed FamilyRoom_Lights_Switch

  run { |event| FamilyRoom_LED_Power.ensure.command(event.state) }
end

received_command(Family_Room_Fan_Button_Action, command: "single") { FamilyRoom_Lights_Switch.toggle }

received_command(Family_Room_Fan_Button_Action, command: "double") { Family_Room_Ceiling_Fan_Light_Power.toggle }

received_command(Family_Room_Fan_Button_Action, command: "hold") { Family_Room_Ceiling_Fan_Fan_Power.toggle }
