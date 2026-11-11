# frozen_string_literal: true

RSpec.describe "family_room.rb" do
  let(:button) { "homeassistant:device:26bcbec1ee:zigbee2mqtt_5F0x282c02bfffee019e" }

  describe "family room lights" do
    it "turns the LEDs on when the lights turn on" do
      FamilyRoom_Lights_Switch.update(ON)

      expect(FamilyRoom_LED_Color).to be_on
    end

    it "turns the LEDs off when the lights turn off" do
      FamilyRoom_Lights_Switch.update(ON)
      FamilyRoom_Lights_Switch.update(OFF)

      expect(FamilyRoom_LED_Color).to be_off
    end
  end

  describe "fan button" do
    it "toggles the lights on a single tap" do
      FamilyRoom_Lights_Switch.update(OFF)
      trigger_channel("#{button}:single", "single")

      expect(FamilyRoom_Lights_Switch).to be_on
    end

    it "toggles the ceiling fan light on a double tap" do
      FamilyRoom_CeilingFan_Light_Power.update(OFF)
      trigger_channel("#{button}:double", "double")

      expect(FamilyRoom_CeilingFan_Light_Power).to be_on
    end

    it "toggles the ceiling fan on a hold" do
      FamilyRoom_CeilingFan_Power.update(OFF)
      trigger_channel("#{button}:hold", "hold")

      expect(FamilyRoom_CeilingFan_Power).to be_on
    end
  end
end
