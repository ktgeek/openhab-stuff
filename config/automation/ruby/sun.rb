# frozen_string_literal: true

# on_start is trigger for startup times
# TODO: add rule to set Sun_Status at start up

updated Entrance_Luminance do |event|
  Sun_Status.ensure.command(event.state.to_i < 170 ? "DOWN" : "UP")
end
