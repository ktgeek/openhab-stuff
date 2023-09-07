# frozen_string_literal: true

RSpec.describe "bedroom.rb" do
  describe "ceiling fan speed" do
    before { autoupdate_all_items }

    it "sets the fan to 0 when the power is turned off" do
      Bedroom_Ceiling_Fan_Speed << 2
      Bedroom_Ceiling_Fan_Power << OFF

      expect(Bedroom_Ceiling_Fan_Speed.state).to eq 0
    end

    it "sets the power to on when the fan speed is set to a value between 1 and 3" do
      states = []

      Bedroom_Ceiling_Fan_Speed << 1
      states << Bedroom_Ceiling_Fan_Power.state

      Bedroom_Ceiling_Fan_Speed << 2
      states << Bedroom_Ceiling_Fan_Power.state

      Bedroom_Ceiling_Fan_Speed << 3
      states << Bedroom_Ceiling_Fan_Power.state

      expect(states.all?(ON)).to be true
    end

    it "sets the power to on when the fan speed is set to any positive value" do
      Bedroom_Ceiling_Fan_Speed << 0

      expect(Bedroom_Ceiling_Fan_Power.state).to be OFF
    end

    it "ignores the speed update to power if speed is not between 0 and 3" do
      Bedroom_Ceiling_Fan_Power.update(OFF)
      Bedroom_Ceiling_Fan_Speed << 4

      expect(Bedroom_Ceiling_Fan_Power.state).to be OFF
    end
  end
end
