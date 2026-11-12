# frozen_string_literal: true

require "sun_status"

RSpec.describe "sun.rb" do
  # Changing Sun_Status also runs entrance_lights.rb, which is told to ignore the luminance here
  before { Entrance_IgnoreLuminance_Switch.update(ON) }

  describe "set Sun_Status from the entrance luminance" do
    it "sets the sun down just below the threshold" do
      Entrance_Luminance.update("169 lx")

      expect(Sun_Status.state).to eq SunStatus::DOWN
    end

    it "sets the sun up at the threshold" do
      Entrance_Luminance.update("170 lx")

      expect(Sun_Status.state).to eq SunStatus::UP
    end

    it "keeps the current status when the luminance becomes unknown" do
      Entrance_Luminance.update("500 lx")
      Entrance_Luminance.update(NULL)

      expect(Sun_Status.state).to eq SunStatus::UP
    end

    it "sets the status on load from the current luminance" do
      suspend_rules { Entrance_Luminance.update("20 lx") }
      rule_named("set Sun_Status from the entrance luminance").trigger

      expect(Sun_Status.state).to eq SunStatus::DOWN
    end
  end
end
