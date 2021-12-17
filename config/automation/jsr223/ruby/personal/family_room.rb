# frozen_string_literal: true

require "openhab"

rule "when family room lights turn on/off, turn on/off LEDS" do
  changed FamilyRoom_Lights_Switch

  triggered { |item| FamilyRoom_LED_Power.ensure << item.state }
end
