# frozen_string_literal: true

# NightOff refers to the VisitorMode item, so it only exists once the rule files have loaded it and it can't be named
# here. The rules are created in each example, which the harness removes again afterwards.
RSpec.describe "NightOff" do
  let(:calls) { [] }
  let(:condition) { -> { true } }
  let(:reactivate) { true }
  let(:night_rule) { rule_named("test: turn off at night") }
  let(:visitor_rule) { rule_named("test: turn off when VisitorMode ends for the night") }

  before do
    calls = self.calls
    NightOff.rule("test", condition:, reactivate:) { calls << :turned_off }
  end

  describe "the 10:30pm rule" do
    it "runs the block when VisitorMode is off" do
      VisitorMode_Switch.update(OFF)
      night_rule.trigger(consider_conditions: true)

      expect(calls).to eq [:turned_off]
    end

    it "does not run the block while VisitorMode is on" do
      VisitorMode_Switch.update(ON)
      night_rule.trigger(consider_conditions: true)

      expect(calls).to be_empty
    end

    context "when the condition is not met" do
      let(:condition) { -> { false } }

      it "does not run the block" do
        VisitorMode_Switch.update(OFF)
        night_rule.trigger(consider_conditions: true)

        expect(calls).to be_empty
      end
    end
  end

  describe "the VisitorMode rule" do
    before { VisitorMode_Switch.update(ON) }

    { "late in the evening" => 23, "after midnight" => 2 }.each do |description, hour|
      it "runs the block when VisitorMode ends #{description}" do
        Timecop.freeze(Time.local(2023, 7, 10, hour, 0, 0))
        VisitorMode_Switch.update(OFF)

        expect(calls).to eq [:turned_off]
      end
    end

    it "does not run the block when VisitorMode ends in the afternoon" do
      Timecop.freeze(Time.local(2023, 7, 10, 15, 0, 0))
      VisitorMode_Switch.update(OFF)

      expect(calls).to be_empty
    end

    context "when the condition is not met" do
      let(:condition) { -> { false } }

      it "does not run the block" do
        Timecop.freeze(Time.local(2023, 7, 10, 23, 0, 0))
        VisitorMode_Switch.update(OFF)

        expect(calls).to be_empty
      end
    end
  end

  context "with reactivate: false" do
    let(:reactivate) { false }

    it "only creates the 10:30pm rule" do
      expect { visitor_rule }.to raise_error(ArgumentError, /No rule named/)
    end
  end

  describe "the block" do
    it "can use ensure_states" do
      calls = self.calls
      NightOff.rule("ensured") { ensure_states { calls << :ensured } }
      VisitorMode_Switch.update(OFF)
      rule_named("ensured: turn off at night").trigger

      expect(calls).to eq [:ensured]
    end
  end
end
