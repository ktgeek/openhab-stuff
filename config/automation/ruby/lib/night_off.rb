# frozen_string_literal: true

# Shared "turn things off for the night" pattern used by evening_lights.rb and holiday.rb:
# - every night at 10:30pm, turn things off, unless VisitorMode is on
# - if VisitorMode gets turned off between 10:30pm and 3am, turn things off immediately instead of waiting for 10:30pm
module NightOff
  # The turn-off blocks run with NightOff as self, so ensure_states, a global DSL method, has to be reachable from here.
  # Extending OpenHAB::DSL instead would make its rule builder call NightOff.rule and recurse.
  def self.ensure_states(&) = OpenHAB::DSL.ensure_states(&)

  def self.rule(label, condition: -> { true }, reactivate: true, &turn_off)
    OpenHAB::DSL.rule "#{label}: turn off at night" do
      cron "0 30 22 ? * *"

      run(&turn_off)

      only_if { ::VisitorMode_Switch.off? && condition.call }
    end

    return unless reactivate

    OpenHAB::DSL.rule "#{label}: turn off when VisitorMode ends for the night" do
      changed ::VisitorMode_Switch, to: ::OFF

      run(&turn_off)

      only_if { Time.now.between?("10:30pm".."3am") && condition.call }
    end
  end
end
