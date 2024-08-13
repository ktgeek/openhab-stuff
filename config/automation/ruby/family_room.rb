# frozen_string_literal: true

rule "when family room lights turn on/off, turn on/off LEDs" do
  changed FamilyRoom_Lights_Switch

  run { |event| FamilyRoom_LED_Power.ensure << event.state }
end

changed(Family_Room_Fan_Button_Action, to: "single") { Family_Room_Ceiling_Fan_Light_Power.toggle }

changed(Family_Room_Fan_Button_Action, to: "double") { FamilyRoom_Lights_Switch.toggle }

changed(Family_Room_Fan_Button_Action, to: "hold") { Family_Room_Ceiling_Fan_Fan_Power.toggle }
