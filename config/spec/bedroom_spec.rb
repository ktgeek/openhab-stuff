# frozen_string_literal: true

RSpec.describe "bedroom.rb" do
  let(:table_remote) { "homeassistant:device:26bcbec1ee:zigbee2mqtt_5F0x70ac08fffe659186" }
  let(:sarah_remote) { "homeassistant:device:26bcbec1ee:zigbee2mqtt_5F0x70ac08fffe5d0c17" }

  describe "closet contact sensors" do
    it "turns Keith's closet light on when the contact opens" do
      Bedroom_KeithsCloset_ContactSensor.update(ON)

      expect(Bedroom_KeithsCloset_Light).to be_on
    end

    it "turns Keith's closet light off when the contact closes" do
      Bedroom_KeithsCloset_Light.update(ON)
      Bedroom_KeithsCloset_ContactSensor.update(OFF)

      expect(Bedroom_KeithsCloset_Light).to be_off
    end

    it "turns Sarah's closet light on immediately when the contact opens" do
      Bedroom_SarahsCloset_ContactSensor.update(ON)

      expect(Bedroom_SarahsCloset_Light).to be_on
    end

    it "turns Sarah's closet light off 30 seconds after the contact closes" do
      Bedroom_SarahsCloset_Light.update(ON)
      Bedroom_SarahsCloset_ContactSensor.update(OFF)

      expect(Bedroom_SarahsCloset_Light).to be_on
      time_travel_and_execute_timers(30.seconds)
      expect(Bedroom_SarahsCloset_Light).to be_off
    end

    it "cancels the pending off timer if the contact reopens within 30 seconds" do
      Bedroom_SarahsCloset_Light.update(ON)
      Bedroom_SarahsCloset_ContactSensor.update(OFF)
      Bedroom_SarahsCloset_ContactSensor.update(ON)

      time_travel_and_execute_timers(30.seconds)
      expect(Bedroom_SarahsCloset_Light).to be_on
    end
  end

  describe "hallway light scene paddle clicks" do
    it "toggles the table light on scene 1" do
      Bedroom_TableLight_Switch.update(OFF)
      Bedroom_Hallway_Light_Scene_1.update(ZWave::Paddle::CLICK)

      expect(Bedroom_TableLight_Switch).to be_on
    end

    it "toggles Sarah's light on scene 2" do
      Bedroom_SarahLight_Switch.update(OFF)
      Bedroom_Hallway_Light_Scene_2.update(ZWave::Paddle::CLICK)

      expect(Bedroom_SarahLight_Switch).to be_on
    end

    it "turns the ceiling fan on when scene 3 is clicked while off" do
      Bedroom_CeilingFan_Speed.update(0)
      Bedroom_Hallway_Light_Scene_3.update(ZWave::Paddle::CLICK)

      expect(Bedroom_CeilingFan_Speed.state).to eq 100
    end

    it "turns the ceiling fan off when scene 3 is clicked while on" do
      Bedroom_CeilingFan_Speed.update(50)
      Bedroom_Hallway_Light_Scene_3.update(ZWave::Paddle::CLICK)

      expect(Bedroom_CeilingFan_Speed.state).to eq 0
    end

    it "toggles the hallway light on scene 4" do
      Bedroom_Hallway_Light_Switch.update(OFF)
      Bedroom_Hallway_Light_Scene_4.update(ZWave::Paddle::CLICK)

      expect(Bedroom_Hallway_Light_Switch).to be_on
    end

    it "toggles the ceiling fan light on scene 5" do
      Bedroom_CeilingFan_Light.update(OFF)
      Bedroom_Hallway_Light_Scene_5.update(ZWave::Paddle::CLICK)

      expect(Bedroom_CeilingFan_Light).to be_on
    end
  end

  describe "remote channel triggers" do
    it "sets fan speed to 1/3 on a single click of button 1" do
      trigger_channel("#{table_remote}:1_single", "1_single")

      expect(Bedroom_CeilingFan_Speed.state.to_f).to be_within(0.1).of(100.0 / 3)
    end

    it "sets fan speed to full on a single click of button 3" do
      trigger_channel("#{table_remote}:3_single", "3_single")

      expect(Bedroom_CeilingFan_Speed.state.to_f).to eq 100
    end

    it "turns the fan off on a double click of button 2" do
      Bedroom_CeilingFan_Speed.update(50)
      trigger_channel("#{table_remote}:2_double", "2_double")

      expect(Bedroom_CeilingFan_Speed.state.to_f).to eq 0
    end

    it "toggles the table light on a single click of button 4 from the table remote" do
      Bedroom_TableLight_Switch.update(OFF)
      trigger_channel("#{table_remote}:4_single", "4_single")

      expect(Bedroom_TableLight_Switch).to be_on
    end

    it "toggles Sarah's light on a single click of button 4 from Sarah's remote" do
      Bedroom_SarahLight_Switch.update(OFF)
      trigger_channel("#{sarah_remote}:4_single", "4_single")

      expect(Bedroom_SarahLight_Switch).to be_on
    end

    it "toggles the ceiling fan light on a double click of button 4" do
      Bedroom_CeilingFan_Light.update(OFF)
      trigger_channel("#{table_remote}:4_double", "4_double")

      expect(Bedroom_CeilingFan_Light).to be_on
    end

    it "toggles Sarah's light on a hold of button 4 from the table remote" do
      Bedroom_SarahLight_Switch.update(OFF)
      trigger_channel("#{table_remote}:4_hold", "4_hold")

      expect(Bedroom_SarahLight_Switch).to be_on
    end
  end
end
