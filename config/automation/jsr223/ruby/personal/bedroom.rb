# frozen_string_literal: true

received_command Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.command)

  # forward command to the actual device as appropriate
  Bedroom_Ceiling_Fan_SpeedDimmer.ensure << (event.command * 100 / 3).ceil
end

changed Bedroom_Ceiling_Fan_SpeedDimmer do
  level = (Bedroom_Ceiling_Fan_SpeedDimmer.state.to_f * 3 / 100).ceil

  # device changed, update the speed item
  Bedroom_Ceiling_Fan_Speed.ensure.update(level)
end
