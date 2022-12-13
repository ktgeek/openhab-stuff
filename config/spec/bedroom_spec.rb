# frozen_string_literal: true

RSpec.describe "bedroom.rb" do
  describe "ceiling fan speed" do
    it "sets the fan to 0 when the dimmer is set to 0" do
      Bedroom_Ceiling_Fan_SpeedDimmer.update(0)

      expect(Bedroom_Ceiling_Fan_Speed.state).to eq 0
    end

    it "sets the fan to 1 when the dimmer is set to 33 or below" do
      Bedroom_Ceiling_Fan_SpeedDimmer.update(33.0)

      expect(Bedroom_Ceiling_Fan_Speed.state).to eq 1
    end

    it "sets the fan to 2 when the dimmer is set between 33 and 66" do
      Bedroom_Ceiling_Fan_SpeedDimmer.update(65.0)

      expect(Bedroom_Ceiling_Fan_Speed.state).to eq 2
    end

    it "sets the fan to 3 when the dimmer is set between 66 and 100" do
      Bedroom_Ceiling_Fan_SpeedDimmer.update(100.0)

      expect(Bedroom_Ceiling_Fan_Speed.state).to eq 3
    end

    it "sets the dimmer to 100 when the fan speed is set to 3" do
      Bedroom_Ceiling_Fan_Speed << 3

      expect(Bedroom_Ceiling_Fan_SpeedDimmer.state).to eq 100
    end

    it "sets the dimmer to 66 when the fan speed is set to 2" do
      Bedroom_Ceiling_Fan_Speed << 2

      expect(Bedroom_Ceiling_Fan_SpeedDimmer.state).to eq 66
    end

    it "sets the dimmer to 33 when the fan speed is set to 1" do
      Bedroom_Ceiling_Fan_Speed << 1

      expect(Bedroom_Ceiling_Fan_SpeedDimmer.state).to eq 33
    end

    it "sets the dimmer to 0 when the fan speed is set to 0" do
      Bedroom_Ceiling_Fan_Speed << 0

      expect(Bedroom_Ceiling_Fan_SpeedDimmer.state).to eq 0
    end
  end
end
