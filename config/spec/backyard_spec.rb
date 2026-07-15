# frozen_string_literal: true

RSpec.describe "backyard.rb" do
  describe "Backyard Lights" do
    it "turns on all members of front lights on when one is sent ON" do
      FamilyRoom_Backyard_Lights_Switch.update(ON)

      expect(Backyard_Lights.members.all?(&:on?)).to be true
    end

    it "turns on all members of front lights off when one is sent OFF" do
      Kitchen_Backyard_Lights_Switch.update(OFF)

      expect(Backyard_Lights.members.all?(&:off?)).to be true
    end
  end

  describe "Office Awtrix outdoor temp text" do
    it "includes the °F unit when the temperature is shorter than 5 characters" do
      allow(Weather).to receive(:feels_like).and_return(72.5)
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      expect(Office_Awtrix_OutdoorTemp_Text.state.to_s).to eq("72.5°F")
    end

    it "omits the °F unit when the temperature is 5 characters long" do
      allow(Weather).to receive(:feels_like).and_return(100.4)
      Backyard_Temperature.update(101)
      time_travel_and_execute_timers(3.seconds)
      expect(Office_Awtrix_OutdoorTemp_Text.state.to_s).to eq("100.4")
    end
  end
end
