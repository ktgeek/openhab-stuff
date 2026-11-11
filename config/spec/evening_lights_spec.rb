# frozen_string_literal: true

RSpec.describe "evening_lights.rb" do
  let(:night_rule) { rule_named("Nights off at end of day: turn off at night") }
  let(:lights) { Front_Yard_Lights.members.to_a + All_Hall_Lights.members.to_a }

  before { suspend_rules { lights.each { |light| light.update(ON) } } }

  describe "nights off at 10:30pm" do
    before { VisitorMode_Switch.update(OFF) }

    it "turns the front yard lights off" do
      night_rule.trigger(consider_conditions: true)

      expect(Front_Yard_Lights.members.all?(&:off?)).to be true
    end

    it "turns the hall lights off" do
      night_rule.trigger(consider_conditions: true)

      expect(All_Hall_Lights.members.all?(&:off?)).to be true
    end

    it "leaves the lights on while VisitorMode is on" do
      VisitorMode_Switch.update(ON)
      night_rule.trigger(consider_conditions: true)

      expect(lights.all?(&:on?)).to be true
    end
  end

  describe "VisitorMode ending" do
    before do
      VisitorMode_Switch.update(ON)
      Timecop.freeze(Time.local(2023, 7, 10, hour, 0, 0))
      VisitorMode_Switch.update(OFF)
    end

    { "late in the evening" => 23, "after midnight" => 1 }.each do |description, time|
      context "when it ends #{description}" do
        let(:hour) { time }

        it "turns the lights off right away" do
          expect(lights.all?(&:off?)).to be true
        end
      end
    end

    context "when it ends in the afternoon" do
      let(:hour) { 15 }

      it "leaves the lights on" do
        expect(lights.all?(&:on?)).to be true
      end
    end
  end

  describe "reset visitor mode" do
    it "turns VisitorMode off at 3am" do
      VisitorMode_Switch.update(ON)
      rule_named("reset visitor mode").trigger

      expect(VisitorMode_Switch).to be_off
    end
  end
end
