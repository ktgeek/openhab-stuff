# frozen_string_literal: true

require "aqara_cube"

updated Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.state)

  Bedroom_Ceiling_Fan_Power.update(event.state.positive?)
end

received_command Bedroom_Ceiling_Fan_Power, command: OFF do
  Bedroom_Ceiling_Fan_Speed << 0
end

rule "When the cube receives an action" do
  updated Bedroom_Cube_Action

  run do |event|
    case event.state
    when AqaraCube::Action::TAP
      Bedroom_Ceiling_Fan_Light_Power.toggle
    when AqaraCube::Action::ROTATE_RIGHT
      Bedroom_Table_Light_Switch.on
    when AqaraCube::Action::ROTATE_LEFT
      Bedroom_Table_Light_Switch.off
    when AqaraCube::Action::FLIP90, AqaraCube::Action::FLIP180
      Bedroom_Ceiling_Fan_Speed << Bedroom_Cube_Side.state if Bedroom_Cube_Side.state < 4
    end
  end
end
