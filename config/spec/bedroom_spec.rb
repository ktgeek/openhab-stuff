# frozen_string_literal: true

RSpec.describe "bedroom.rb" do
  let(:table_remote) { "homeassistant:device:26bcbec1ee:zigbee2mqtt_5F0x70ac08fffe659186" }
  let(:sarah_remote) { "homeassistant:device:26bcbec1ee:zigbee2mqtt_5F0x70ac08fffe5d0c17" }

  def press(remote, event)
    trigger_channel("#{remote}:#{event}", event)
  end

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

    context "when Sarah's closet contact closes" do
      before do
        Bedroom_SarahsCloset_Light.update(ON)
        Bedroom_SarahsCloset_ContactSensor.update(OFF)
      end

      it "leaves her closet light on for the first 29 seconds" do
        time_travel_and_execute_timers(29.seconds)

        expect(Bedroom_SarahsCloset_Light).to be_on
      end

      it "turns her closet light off after 30 seconds" do
        time_travel_and_execute_timers(30.seconds)

        expect(Bedroom_SarahsCloset_Light).to be_off
      end

      it "keeps her closet light on if the contact reopens within 30 seconds" do
        Bedroom_SarahsCloset_ContactSensor.update(ON)
        time_travel_and_execute_timers(30.seconds)

        expect(Bedroom_SarahsCloset_Light).to be_on
      end
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

  describe "remote fan buttons" do
    remotes = %i[table_remote sarah_remote]

    { "1_single" => 100.0 / 3, "2_single" => 200.0 / 3, "3_single" => 100.0 }.each do |event, speed|
      remotes.each do |remote|
        it "sets fan speed for #{event} from the #{remote.to_s.tr('_', ' ')}" do
          press(send(remote), event)

          expect(Bedroom_CeilingFan_Speed.state.to_f).to be_within(0.1).of(speed)
        end
      end
    end

    %w[1_double 2_double 3_double].each do |event|
      remotes.each do |remote|
        it "turns the fan off for #{event} from the #{remote.to_s.tr('_', ' ')}" do
          Bedroom_CeilingFan_Speed.update(50)
          press(send(remote), event)

          expect(Bedroom_CeilingFan_Speed.state.to_f).to eq 0
        end
      end
    end
  end

  describe "remote button 4" do
    it "toggles the table light on a single click from the table remote" do
      Bedroom_TableLight_Switch.update(OFF)
      press(table_remote, "4_single")

      expect(Bedroom_TableLight_Switch).to be_on
    end

    it "toggles Sarah's light on a single click from Sarah's remote" do
      Bedroom_SarahLight_Switch.update(OFF)
      press(sarah_remote, "4_single")

      expect(Bedroom_SarahLight_Switch).to be_on
    end

    it "leaves Sarah's light alone on a single click from the table remote" do
      Bedroom_SarahLight_Switch.update(OFF)
      press(table_remote, "4_single")

      expect(Bedroom_SarahLight_Switch).to be_off
    end

    %i[table_remote sarah_remote].each do |remote|
      it "toggles the ceiling fan light on a double click from the #{remote.to_s.tr('_', ' ')}" do
        Bedroom_CeilingFan_Light.update(OFF)
        press(send(remote), "4_double")

        expect(Bedroom_CeilingFan_Light).to be_on
      end
    end

    it "toggles Sarah's light on a hold from the table remote" do
      Bedroom_SarahLight_Switch.update(OFF)
      press(table_remote, "4_hold")

      expect(Bedroom_SarahLight_Switch).to be_on
    end
  end
end
