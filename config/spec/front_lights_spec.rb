# frozen_string_literal: true

RSpec.describe "front_lights.rb" do
  # Changing Sun_Status also runs entrance_lights.rb, which would turn the lights on or off behind these examples' backs
  before { Entrance_IgnoreLuminance_Switch.update(ON) }

  describe "Hall Lights" do
    it "turns on all the hall lights when one is turned on" do
      All_Hall_Lights.members.first.update(ON)

      expect(All_Hall_Lights.members.all?(&:on?)).to be true
    end

    it "turns off all the hall lights when one is turned off" do
      suspend_rules { All_Hall_Lights.members.each { |light| light.update(ON) } }
      All_Hall_Lights.members.first.update(OFF)

      expect(All_Hall_Lights.members.all?(&:off?)).to be true
    end
  end

  describe "Front Yard light switch buttons" do
    %w[porch-light-switch garage-outdoor-light-switch].each do |switch|
      context "when the #{switch} is pressed once" do
        let(:button) { "esphome:device:#{switch}:button" }

        it "turns the front yard lights on if they are off" do
          Front_Yard_Lights.members.each { |light| light.update(OFF) }
          trigger_channel(button, "single")

          expect(Front_Yard_Lights.members.all?(&:on?)).to be true
        end

        it "turns the front yard lights off if they are on" do
          Front_Yard_Lights.members.each { |light| light.update(ON) }
          trigger_channel(button, "single")

          expect(Front_Yard_Lights.members.all?(&:off?)).to be true
        end
      end
    end
  end

  describe "morning lights for bike rides" do
    let(:morning_rule) { rules["morning_lights_on_for_rides"] }

    before do
      Outdoor_Biking_Season.update(ON)
      Sun_Status.update(SunStatus::DOWN)
    end

    it "turns on the front yard lights at 5am if the sun is down and it's outdoor biking season" do
      morning_rule.trigger

      expect(Front_Yard_Lights.members.all?(&:on?)).to be true
    end

    it "turns on the outdoor decorations when there is a holiday" do
      Holiday_Mode.update("Halloween")

      morning_rule.trigger

      expect(Front_Yard_Outdoor_Decorations_Switch).to be_on
    end

    it "leaves the outdoor decorations off when there is no holiday" do
      morning_rule.trigger

      expect(Front_Yard_Outdoor_Decorations_Switch).not_to be_on
    end

    it "does nothing if the Sun is up" do
      Sun_Status.update(SunStatus::UP)

      morning_rule.trigger

      expect(Front_Yard_Lights.members.none?(&:on?)).to be true
    end

    it "does nothing if it is not outdoor biking season" do
      Outdoor_Biking_Season.update(OFF)

      morning_rule.trigger

      expect(Front_Yard_Lights.members.none?(&:on?)).to be true
    end
  end

  describe "normal morning lights" do
    let(:morning_rule) { rules["morning_lights_on"] }

    it "does nothing if the Sun is up" do
      Sun_Status.update(SunStatus::UP)

      morning_rule.trigger

      expect(Front_Yard_Lights.members.none?(&:on?)).to be true
    end

    it "turns on the lights if the Sun is down" do
      Sun_Status.update(SunStatus::DOWN)

      morning_rule.trigger

      expect(Front_Yard_Lights.members.all?(&:on?)).to be true
    end

    it "turns on the outdoor decorations if the Sun is down and there is a holiday" do
      Sun_Status.update(SunStatus::DOWN)
      Holiday_Mode.update("Halloween")

      morning_rule.trigger

      expect(Front_Yard_Outdoor_Decorations_Switch).to be_on
    end

    it "leaves the outdoor decorations off if the Sun is down and there is no holiday" do
      Sun_Status.update(SunStatus::DOWN)

      morning_rule.trigger

      expect(Front_Yard_Outdoor_Decorations_Switch).not_to be_on
    end
  end
end
