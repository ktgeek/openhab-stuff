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
end
