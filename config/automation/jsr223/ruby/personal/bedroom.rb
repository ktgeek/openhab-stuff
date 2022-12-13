# frozen_string_literal: true

received_command Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.command)

  value = (event.command * 100 / 3).floor
  # logger.warn("I am executing the rule for #{value}")

  # forward command to the actual device as appropriate
  Bedroom_Ceiling_Fan_SpeedDimmer.ensure << value
end

changed Bedroom_Ceiling_Fan_SpeedDimmer do |event|
  level = (event.state.to_f * 3 / 100).ceil

  # logger.warn("I am executing the rule for #{level}")

  # device changed, update the speed item
  Bedroom_Ceiling_Fan_Speed.ensure.update(level)
end
