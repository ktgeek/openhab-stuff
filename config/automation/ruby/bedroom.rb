# frozen_string_literal: true

require "aqara_cube"

updated Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.state)

  Bedroom_Ceiling_Fan_Power.update(event.state.positive?)
end

received_command Bedroom_Ceiling_Fan_Power, command: OFF do
  Bedroom_Ceiling_Fan_Speed << 0
end

updated Bedroom_Cube_Action, to: AqaraCube::Action::TAP do
  Bedroom_Ceiling_Fan_Light_Power.toggle
end

updated Bedroom_Cube_Action, to: AqaraCube::Action::ROTATE_RIGHT do
  Bedroom_Table_Light_Switch.on
end

updated Bedroom_Cube_Action, to: AqaraCube::Action::ROTATE_LEFT do
  Bedroom_Table_Light_Switch.off
end

updated Bedroom_Cube_Action, to: [AqaraCube::Action::FLIP90, AqaraCube::Action::FLIP180] do
  Bedroom_Ceiling_Fan_Speed << Bedroom_Cube_Side.state if Bedroom_Cube_Side.state < 4
end
