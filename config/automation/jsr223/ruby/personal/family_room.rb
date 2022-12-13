# frozen_string_literal: true

rule "when family room lights turn on/off, turn on/off LEDs" do
  changed FamilyRoom_Lights_Switch

  run { |event| FamilyRoom_LED_Power.ensure << event.state }
end
