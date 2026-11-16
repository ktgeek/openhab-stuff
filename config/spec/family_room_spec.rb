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

  describe "harmony activity switches" do
    before { allow(FamilyRoom_Harmony_Activity).to receive(:command) }

    it "starts Watch TV when its switch is commanded on" do
      FamilyRoom_Harmony_WatchTV_Switch.command(ON)

      expect(FamilyRoom_Harmony_Activity).to have_received(:command).with("Watch TV")
    end

    it "starts Watch PC when its switch is commanded on" do
      FamilyRoom_Harmony_WatchPC_Switch.command(ON)

      expect(FamilyRoom_Harmony_Activity).to have_received(:command).with("Watch PC")
    end

    it "starts Listen to Music when its switch is commanded on" do
      FamilyRoom_Harmony_ListenToMusic_Switch.command(ON)

      expect(FamilyRoom_Harmony_Activity).to have_received(:command).with("Listen to Music")
    end

    it "powers off when the switch of the running activity is commanded off" do
      FamilyRoom_Harmony_Activity.update("Watch TV")
      FamilyRoom_Harmony_WatchTV_Switch.command(OFF)

      expect(FamilyRoom_Harmony_Activity).to have_received(:command).with("PowerOff")
    end

    it "leaves a different running activity alone when a switch is commanded off" do
      FamilyRoom_Harmony_Activity.update("Watch TV")
      FamilyRoom_Harmony_WatchPC_Switch.command(OFF)

      expect(FamilyRoom_Harmony_Activity).not_to have_received(:command)
    end

    it "turns on the switch of the activity that started" do
      FamilyRoom_Harmony_Activity.update("Watch PC")

      expect(FamilyRoom_Harmony_WatchPC_Switch).to be_on
    end

    it "turns off the switch of the activity that was replaced" do
      FamilyRoom_Harmony_Activity.update("Watch TV")
      FamilyRoom_Harmony_Activity.update("Watch PC")

      expect(FamilyRoom_Harmony_WatchTV_Switch).to be_off
    end

    it "turns the switches off when the system powers off" do
      FamilyRoom_Harmony_Activity.update("Watch TV")
      FamilyRoom_Harmony_Activity.update("PowerOff")

      expect(FamilyRoom_Harmony_WatchTV_Switch).to be_off
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
