# frozen_string_literal: true

RSpec.describe "entrance_lights.rb" do
  before { Entrance_IgnoreLuminance_Switch.update(OFF) }

  def lights_on
    suspend_rules do
      Front_Yard_Lights.members.each { |light| light.update(ON) }
      All_Hall_Lights.members.each { |light| light.update(ON) }
    end
  end

  # Mondays and Saturdays: July 10th, 2023 was a Monday
  def freeze_at(day, hour, minute = 0)
    Timecop.freeze(Time.local(2023, 7, day == :weekday ? 10 : 8, hour, minute, 0))
  end

  describe "when the sun goes down" do
    before { Sun_Status.update(SunStatus::UP) }

    context "when it is a weekday between 9am and 10:30pm" do
      before do
        freeze_at(:weekday, 10)
        Sun_Status.update(SunStatus::DOWN)
      end

      it "turns on the front yard lights" do
        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end

      it "turns on the hall lights" do
        expect(All_Hall_Lights.members.all?(&:on?)).to be true
      end
    end

    context "when it is a weekday between 5:35am and 9am" do
      before do
        freeze_at(:weekday, 5, 40)
        Sun_Status.update(SunStatus::DOWN)
      end

      it "turns on the front yard lights" do
        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end

      it "leaves the hall lights off until 9am" do
        expect(All_Hall_Lights.members.none?(&:on?)).to be true
      end
    end

    context "when it is a weekday before 5:35am" do
      before do
        freeze_at(:weekday, 5)
        Sun_Status.update(SunStatus::DOWN)
      end

      it "leaves the front yard lights off" do
        expect(Front_Yard_Lights.members.none?(&:on?)).to be true
      end

      it "leaves the hall lights off" do
        expect(All_Hall_Lights.members.none?(&:on?)).to be true
      end
    end

    context "when it is after 10:30pm" do
      before do
        freeze_at(:weekday, 23)
        Sun_Status.update(SunStatus::DOWN)
      end

      it "leaves the front yard lights off" do
        expect(Front_Yard_Lights.members.none?(&:on?)).to be true
      end
    end

    context "when it is a weekend between 5:35am and 9am" do
      before do
        freeze_at(:weekend, 6)
        Sun_Status.update(SunStatus::DOWN)
      end

      it "leaves the front yard lights off until 9am" do
        expect(Front_Yard_Lights.members.none?(&:on?)).to be true
      end

      it "leaves the hall lights off until 9am" do
        expect(All_Hall_Lights.members.none?(&:on?)).to be true
      end
    end

    context "when it is a weekend between 9am and 10:30pm" do
      before do
        freeze_at(:weekend, 10)
        Sun_Status.update(SunStatus::DOWN)
      end

      it "turns on the front yard lights" do
        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end

      it "turns on the hall lights" do
        expect(All_Hall_Lights.members.all?(&:on?)).to be true
      end
    end

    context "when luminance is being ignored" do
      before do
        Entrance_IgnoreLuminance_Switch.update(ON)
        freeze_at(:weekday, 10)
        Sun_Status.update(SunStatus::DOWN)
      end

      it "leaves the front yard lights off" do
        expect(Front_Yard_Lights.members.none?(&:on?)).to be true
      end

      it "leaves the hall lights off" do
        expect(All_Hall_Lights.members.none?(&:on?)).to be true
      end
    end
  end

  describe "when the sun comes up" do
    before do
      Sun_Status.update(SunStatus::DOWN)
      lights_on
    end

    context "when it is a weekday between 5:35am and 10:30pm" do
      before { freeze_at(:weekday, 10) }

      it "turns off the front yard lights" do
        Sun_Status.update(SunStatus::UP)

        expect(Front_Yard_Lights.members.all?(&:off?)).to be true
      end

      it "turns off the hall lights" do
        Sun_Status.update(SunStatus::UP)

        expect(All_Hall_Lights.members.all?(&:off?)).to be true
      end

      it "turns off the outdoor decorations when there is a holiday" do
        Holiday_Mode.update("Halloween")
        Front_Yard_Outdoor_Decorations_Switch.update(ON)
        Sun_Status.update(SunStatus::UP)

        expect(Front_Yard_Outdoor_Decorations_Switch).to be_off
      end

      it "leaves the outdoor decorations alone when there is no holiday" do
        Front_Yard_Outdoor_Decorations_Switch.update(ON)
        Sun_Status.update(SunStatus::UP)

        expect(Front_Yard_Outdoor_Decorations_Switch).to be_on
      end
    end

    context "when it is a weekday before 5:35am" do
      before do
        freeze_at(:weekday, 5)
        Sun_Status.update(SunStatus::UP)
      end

      it "leaves the front yard lights on" do
        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end

      it "leaves the hall lights on" do
        expect(All_Hall_Lights.members.all?(&:on?)).to be true
      end
    end

    context "when it is after 10:30pm" do
      before do
        freeze_at(:weekday, 23)
        Sun_Status.update(SunStatus::UP)
      end

      it "leaves the front yard lights on" do
        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end
    end

    context "when it is a weekend before 9am" do
      before do
        freeze_at(:weekend, 6)
        Sun_Status.update(SunStatus::UP)
      end

      it "leaves the front yard lights on" do
        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end
    end

    context "when luminance is being ignored" do
      before do
        Entrance_IgnoreLuminance_Switch.update(ON)
        freeze_at(:weekday, 10)
        Sun_Status.update(SunStatus::UP)
      end

      it "leaves the front yard lights on" do
        expect(Front_Yard_Lights.members.all?(&:on?)).to be true
      end

      it "leaves the hall lights on" do
        expect(All_Hall_Lights.members.all?(&:on?)).to be true
      end
    end
  end
end
