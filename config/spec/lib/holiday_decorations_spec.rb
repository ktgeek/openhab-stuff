# frozen_string_literal: true

# HolidayDecorations refers to items, so it only exists once the rule files have loaded it and it can't be named here.
# The rules are created in each example, which the harness removes again afterwards, and are triggered by hand so the
# real holiday rules don't react to the item changes.
RSpec.describe "HolidayDecorations" do
  let(:calls) { [] }
  let(:holiday) { Holidays::CHRISTMAS }
  let(:reactivate) { true }

  def sunset_rule
    rule_named("decorations on at sunset at test")
  end

  def night_rule
    rule_named("decorations at test: turn off at night")
  end

  def visitor_rule
    rule_named("decorations at test: turn off when VisitorMode ends for the night")
  end

  before do
    calls = self.calls
    HolidayDecorations.rule(
      "test", Holidays::CHRISTMAS,
      reactivate:,
      on: proc { calls << :on },
      off: proc { calls << :off }
    )
    suspend_rules do
      Holiday_Mode.update(holiday)
      VisitorMode_Switch.update(OFF)
    end
  end

  describe "the sunset rule" do
    it "runs the on block during the holiday" do
      sunset_rule.trigger(consider_conditions: true)

      expect(calls).to eq [:on]
    end

    context "when it is another holiday" do
      let(:holiday) { Holidays::HALLOWEEN }

      it "does not run the on block" do
        sunset_rule.trigger(consider_conditions: true)

        expect(calls).to be_empty
      end
    end
  end

  describe "the night rule" do
    it "runs the off block during the holiday" do
      night_rule.trigger(consider_conditions: true)

      expect(calls).to eq [:off]
    end

    context "when it is another holiday" do
      let(:holiday) { Holidays::HALLOWEEN }

      it "does not run the off block" do
        night_rule.trigger(consider_conditions: true)

        expect(calls).to be_empty
      end
    end
  end

  describe "the VisitorMode rule" do
    it "exists by default" do
      expect { visitor_rule }.not_to raise_error
    end

    context "with reactivate: false" do
      let(:reactivate) { false }

      it "is not created" do
        expect { visitor_rule }.to raise_error(ArgumentError, /No rule named/)
      end
    end
  end

  describe "the blocks" do
    it "can use ensure_states" do
      calls = self.calls
      HolidayDecorations.rule(
        "ensured", Holidays::CHRISTMAS,
        on: proc { ensure_states { calls << :on_ensured } },
        off: proc { ensure_states { calls << :off_ensured } }
      )
      rule_named("decorations on at sunset at ensured").trigger(consider_conditions: true)
      rule_named("decorations at ensured: turn off at night").trigger(consider_conditions: true)

      expect(calls).to eq %i[on_ensured off_ensured]
    end
  end
end
