# frozen_string_literal: true

updated Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.state)

  Bedroom_Ceiling_Fan_Power.update(event.state.positive?)
end

received_command Bedroom_Ceiling_Fan_Power, command: OFF do
  Bedroom_Ceiling_Fan_Speed.ensure << 0
end
