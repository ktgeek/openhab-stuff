# frozen_string_literal: true

# on_start is trigger for startup times
# TODO: add rule to set Sun_Status at start up

# rule "when daylight starts" do
#   channel "astro:sun:local:daylight#event", triggered: "START"
#   run { Sun_Status << "UP" }
# end

# rule "when daylight ends" do
#   channel "astro:sun:local:daylight#event", triggered: "END"
#   run { Sun_Status << "DOWN" }
# end

updated Entrance_Luminance do |event|
  Sun_Status.ensure << (event.state.to_i < 170 ? "DOWN" : "UP")
end
