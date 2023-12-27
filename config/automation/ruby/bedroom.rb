# frozen_string_literal: true

updated Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.state)

  Bedroom_Ceiling_Fan_Power.update(event.state.positive?)
end

received_command(Bedroom_Ceiling_Fan_Power, command: OFF) { Bedroom_Ceiling_Fan_Speed << 0 }

changed Bedroom_Remotes_Action.members, to: %w[1_single 2_single 3_single] do |event|
  Bedroom_Ceiling_Fan_Speed << event.state[0].to_i
end

changed(Bedroom_Remotes_Action.members, to: %w[1_double 2_double 3_double]) { Bedroom_Ceiling_Fan_Speed << 0 }

changed Bedroom_Remotes_Action.members, to: "4_single" do |event|
  switch = items["Bedroom_#{event.item_name.split('_')[1]}_Light_Switch"]
  switch.toggle
end

changed(Bedroom_Remotes_Action.members, to: "4_double") { Bedroom_Ceiling_Fan_Light_Power.toggle }

changed Bedroom_Keiths_Closet_Contact_Sensor do |event|
  Bedroom_Keith_Closet_Light.ensure << (event.state == OPEN)
end

changed Bedroom_Sarahs_Closet_Contact_Sensor, to: OPEN do |event|
  timers.cancel(event.item)
  Bedroom_Sarah_Closet_Light.ensure.on
end

changed Bedroom_Sarahs_Closet_Contact_Sensor, to: CLOSED do |event|
  after(30.seconds, id: event.item) { Bedroom_Sarah_Closet_Light.ensure.off }
end
