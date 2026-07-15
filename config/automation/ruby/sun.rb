# frozen_string_literal: true

require "sun_status"

# Below this luminance (lux) at the entrance window, we consider the sun down.
SUN_LUMINANCE_THRESHOLD = 170

rule "set Sun_Status from the entrance luminance" do
  updated Entrance_Luminance
  on_load

  run do
    state = Entrance_Luminance.state
    next if state.nil?

    Sun_Status.ensure.command(state.to_i < SUN_LUMINANCE_THRESHOLD ? SunStatus::DOWN : SunStatus::UP)
  end
end
