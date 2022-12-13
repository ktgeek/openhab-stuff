# frozen_string_literal: true

RSpec.describe "entrance_lights.rb" do
  describe "Hall Lights" do
    it "turns on all members of hall lights on when one is sent ON" do
      All_Hall_Lights.members.first.update(ON)

      expect(All_Hall_Lights.members.all?(&:on?)).to be true
    end

    it "turns on all members of hall lights off when one is sent OFF" do
      All_Hall_Lights.members.first.update(OFF)

      expect(All_Hall_Lights.members.all?(&:off?)).to be true
    end
  end
end
