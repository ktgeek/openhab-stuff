# frozen_string_literal: true

RSpec.describe "holiday.rb" do
  let(:zoom) { OFF }
  let(:decorations) do
    [Porch_Decorations_Switch, Front_Yard_Side_Holiday_Decorations_Switch,
     HiddenRoom_HolidayLED_Power, DinahsRoom_HolidayLED_Power]
  end

  # Changing Sun_Status also runs entrance_lights.rb, so it is told to ignore the luminance. The holiday rules react to
  # the sun once a holiday is set, so the sun is set first.
  before do
    suspend_rules do
      Entrance_IgnoreLuminance_Switch.update(ON)
      Office_Bugg_Zoom.update(zoom)
      Office_Bugg_GIRobot.update(OFF)
      VisitorMode_Switch.update(OFF)
    end
  end

  def sunset_at(holiday)
    Sun_Status.update(SunStatus::UP)
    Holiday_Mode.update(holiday)
    Sun_Status.update(SunStatus::DOWN)
  end

  describe "sun up" do
    before do
      Sun_Status.update(SunStatus::DOWN)
      suspend_rules do
        (decorations + [Office_DoorLED_Color]).each { |item| item.update(ON) }
      end
    end

    context "when a holiday is set" do
      before do
        Holiday_Mode.update(Holidays::HALLOWEEN)
        Sun_Status.update(SunStatus::UP)
      end

      it "turns off the porch decorations" do
        expect(Porch_Decorations_Switch).to be_off
      end

      it "turns off the side holiday decorations" do
        expect(Front_Yard_Side_Holiday_Decorations_Switch).to be_off
      end

      it "turns off the office door LED" do
        expect(Office_DoorLED_Color).to be_off
      end
    end

    context "without a holiday" do
      before { Sun_Status.update(SunStatus::UP) }

      it "leaves the decorations on" do
        expect(Porch_Decorations_Switch).to be_on
      end
    end
  end

  describe "sunset at Halloween" do
    before { sunset_at(Holidays::HALLOWEEN) }

    it "turns on the porch decorations" do
      expect(Porch_Decorations_Switch).to be_on
    end

    it "turns on the side holiday decorations" do
      expect(Front_Yard_Side_Holiday_Decorations_Switch).to be_on
    end

    it "turns on the hidden room LEDs" do
      expect(HiddenRoom_HolidayLED_Power).to be_on
    end

    it "turns on Dinah's room LEDs" do
      expect(DinahsRoom_HolidayLED_Power).to be_on
    end

    it "fades the office door LED" do
      expect(Office_DoorLED_Fade).to be_on
    end

    it "sets the office door LED to purple" do
      expect(Office_DoorLED_Color.state).to eq Color::PURPLE
    end

    it "sets the office door LED to the purple fade effect" do
      expect(Office_DoorLED_LightEffects.state).to eq Esphome::LC5050C::Effects::PURPLE_FADE
    end

    context "when a Zoom meeting is on" do
      let(:zoom) { ON }

      it "leaves the office door LED alone" do
        expect(Office_DoorLED_Fade).not_to be_on
      end
    end
  end

  describe "sunset on another holiday" do
    it "leaves the Halloween decorations off" do
      sunset_at(Holidays::STPATRICKS)

      expect(Porch_Decorations_Switch).not_to be_on
    end
  end

  describe "sunset at St. Patty" do
    before { sunset_at(Holidays::STPATRICKS) }

    it "sets the office door LED to green" do
      expect(Office_DoorLED_Color.state).to eq Color::GREEN
    end

    context "when a Zoom meeting is on" do
      let(:zoom) { ON }

      it "leaves the office door LED alone" do
        expect(Office_DoorLED_Color.state).not_to eq Color::GREEN
      end
    end
  end

  describe "sunset at Christmas" do
    before { sunset_at(Holidays::CHRISTMAS) }

    it "turns on the outside decorations" do
      expect(Christmas_Outside.members.all?(&:on?)).to be true
    end

    it "turns on the Christmas lights" do
      expect(Christmas_Lights.members.all?(&:on?)).to be true
    end
  end

  describe "turning the Christmas lights on" do
    # The group is only on once its last member is, so all but one member go on without the rules watching
    before do
      Holiday_Mode.update(Holidays::CHRISTMAS)
      *others, last = Christmas_Lights.members.to_a
      suspend_rules do
        Christmas_Lights.members.each { |light| light.update(OFF) }
        others.each { |light| light.update(ON) }
      end
      last.update(ON)
    end

    it "fades the office door LED" do
      expect(Office_DoorLED_Fade).to be_on
    end

    it "sets the office door LED to the red green crossfade effect" do
      expect(Office_DoorLED_LightEffects.state).to eq Esphome::LC5050C::Effects::RED_GREEN_CROSSFADE
    end

    context "when a Zoom meeting is on" do
      let(:zoom) { ON }

      it "leaves the office door LED alone" do
        expect(Office_DoorLED_Fade).not_to be_on
      end
    end
  end

  describe "turning off at night" do
    before do
      suspend_rules do
        Holiday_Mode.update(holiday)
        (decorations + Christmas_Outside.members.to_a + Christmas_Lights_All.members.to_a + [Office_DoorLED_Color])
          .each { |item| item.update(ON) }
      end
      rule_named("decorations at #{label}: turn off at night").trigger(consider_conditions: true)
    end

    context "when it is Halloween" do
      let(:holiday) { Holidays::HALLOWEEN }
      let(:label) { "Halloween" }

      it "turns off the decorations" do
        expect(decorations.all?(&:off?)).to be true
      end

      it "turns off the office door LED" do
        expect(Office_DoorLED_Color).to be_off
      end
    end

    context "when it is St. Patty" do
      let(:holiday) { Holidays::STPATRICKS }
      let(:label) { "St.Patty" }

      it "turns off the office door LED" do
        expect(Office_DoorLED_Color).to be_off
      end
    end

    context "when it is Christmas" do
      let(:holiday) { Holidays::CHRISTMAS }
      let(:label) { "Christmas" }

      it "turns off the outside decorations" do
        expect(Christmas_Outside.members.all?(&:off?)).to be true
      end

      it "turns off the rest of the Christmas lights" do
        expect(Christmas_Lights_All.members.all?(&:off?)).to be true
      end
    end

    context "when it is another holiday" do
      let(:holiday) { Holidays::CHRISTMAS }
      let(:label) { "Halloween" }

      it "leaves the Halloween decorations on" do
        expect(Porch_Decorations_Switch).to be_on
      end
    end
  end
end
