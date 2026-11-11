# frozen_string_literal: true

RSpec.describe "front_lights.rb" do
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

  describe "Front Yard Lights" do
    context "morning lights for bike rides" do
      it "turns on the front yard lights at 5am if the sun is down and its outdoor biking season" do
        Outdoor_Biking_Season.update(ON)
        Sun_Status.update("DOWN")

        rules["morning_lights_on_for_rides"].trigger

        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end

      it "turns on the outdoor decorations at 5am if the sun is down and its outdoor biking season and there is a holiday" do
        Outdoor_Biking_Season.update(ON)
        Sun_Status.update("DOWN")
        Holiday_Mode.update("Halloween")

        rules["morning_lights_on_for_rides"].trigger

        expect(Front_Yard_Outdoor_Decorations_Switch).to be_on
      end

      it "does nothing if the Sun is up" do
        Outdoor_Biking_Season.update(ON)
        Sun_Status.update("UP")

        rules["morning_lights_on_for_rides"].trigger

        expect(Front_Yard_Lights.members.none?(&:on?)).to be true
      end

      it "does nothing if it is not outdoor biking season" do
        Outdoor_Biking_Season.update(OFF)
        Sun_Status.update("DOWN")

        rules["morning_lights_on_for_rides"].trigger

        expect(Front_Yard_Lights.members.none?(&:on?)).to be true
      end
    end

    context "normal morning lights" do
      it "does nothing if the Sun is up" do
        Sun_Status.update("UP")

        rules["morning_lights_on"].trigger

        expect(Front_Yard_Lights.members.none?(&:on?)).to be true
      end

      it "turns on the lights if the Sun is down" do
        Sun_Status.update("DOWN")

        rules["morning_lights_on"].trigger

        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end

      it "turns on the outdoor decorations if the Sun is down and there is a holiday" do
        Sun_Status.update("DOWN")
        Holiday_Mode.update("Halloween")

        rules["morning_lights_on"].trigger

        expect(Front_Yard_Outdoor_Decorations_Switch).to be_on
      end
    end
  end
end
