# frozen_string_literal: true

RSpec.describe "kitchen_bathroom.rb" do
  before do
    suspend_rules do
      KitchenBathroom_Light_Switch.update(ON)
      KitchenBathroom_Fan_Switch.update(ON)
    end
  end

  context "when the contact sensor turns on" do
    before { KitchenBathroom_ContactSensor.update(ON) }

    it "leaves the light on for the first 2 minutes" do
      time_travel_and_execute_timers(119.seconds)

      expect(KitchenBathroom_Light_Switch).to be_on
    end

    it "turns the light off after 2 minutes" do
      time_travel_and_execute_timers(2.minutes)

      expect(KitchenBathroom_Light_Switch).to be_off
    end

    it "leaves the fan on for the first 5 minutes" do
      time_travel_and_execute_timers(299.seconds)

      expect(KitchenBathroom_Fan_Switch).to be_on
    end

    it "turns the fan off after 5 minutes" do
      time_travel_and_execute_timers(5.minutes)

      expect(KitchenBathroom_Fan_Switch).to be_off
    end
  end

  context "when the contact sensor turns off before the timers run out" do
    before do
      KitchenBathroom_ContactSensor.update(ON)
      time_travel_and_execute_timers(1.minute)
      KitchenBathroom_ContactSensor.update(OFF)
      time_travel_and_execute_timers(5.minutes)
    end

    it "keeps the light on" do
      expect(KitchenBathroom_Light_Switch).to be_on
    end

    it "keeps the fan on" do
      expect(KitchenBathroom_Fan_Switch).to be_on
    end
  end
end
