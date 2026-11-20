# frozen_string_literal: true

require "holidays"
require "night_off"
require "sun_status"

# The decoration rules for one holiday, used by holiday.rb:
# - at sunset, run `on`, but only while that holiday is current
# - at night, run `off` the way NightOff does, including `reactivate` for when VisitorMode ends overnight
# `on` and `off` are procs and are called, not passed to `run`, so they keep the self of the file that defined them and
# with it the global DSL methods (ensure_states, items, ...).
module HolidayDecorations
  def self.rule(label, holiday, on:, off:, reactivate: true)
    OpenHAB::DSL.rule "decorations on at sunset at #{label}" do
      changed ::Sun_Status, to: SunStatus::DOWN

      run { on.call }

      only_if { Holidays.current?(holiday) }
    end

    NightOff.rule("decorations at #{label}", condition: -> { Holidays.current?(holiday) }, reactivate:, &off)
  end
end
