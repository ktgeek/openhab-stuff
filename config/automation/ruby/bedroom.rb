# frozen_string_literal: true

updated Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.state)

  Bedroom_Ceiling_Fan_Power.update(event.state.positive?)
end

received_command Bedroom_Ceiling_Fan_Power, command: OFF do
  Bedroom_Ceiling_Fan_Speed << 0
end

updated Bedroom_Remotes_Action.members, to: %w[1_single 2_single 3_single] do |event|
  Bedroom_Ceiling_Fan_Speed << event.state[0].to_i
end

updated Bedroom_Remotes_Action.members, to: %w[1_double 2_double 3_double] do
  Bedroom_Ceiling_Fan_Speed << 0
end

updated Bedroom_Remotes_Action.members, to: "4_single" do |event|
  switch = items["Bedroom_#{event.item_name.split('_')[1]}_Light_Switch"]
  switch.toggle
end

updated Bedroom_Remotes_Action.members, to: "4_double" do
  Bedroom_Ceiling_Fan_Light_Power.toggle
end
