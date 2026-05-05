# frozen_string_literal: true

require "zwave"
require "zigbee"

BEDROOM_REMOTES = [Bedroom_Table_Remote_Battery.thing, Bedroom_Sarah_Remote_Battery.thing].freeze

updated Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.state)

  Bedroom_Ceiling_Fan_Power.update(event.state.positive?)
end

received_command(Bedroom_Ceiling_Fan_Power, command: OFF) { Bedroom_Ceiling_Fan_Speed.command(0) }

channel(%w[1_single 2_single 3_single], thing: BEDROOM_REMOTES) do |event|
  Bedroom_Ceiling_Fan_Speed.command(event.event[0].to_i)
end

channel(%w[1_double 2_double 3_double], thing: BEDROOM_REMOTES) do
  Bedroom_Ceiling_Fan_Speed.command(0)
end

channel("4_single", thing: BEDROOM_REMOTES) do |event|
  switch = items["Bedroom_#{event.thing.label.split[1]}_Light_Switch"]
  switch&.toggle
end

channel("4_double", thing: BEDROOM_REMOTES) { Bedroom_Ceiling_Fan_Light_Power.toggle }

channel("4_hold", thing: BEDROOM_REMOTES.first) { Bedroom_Sarah_Light_Switch.toggle }

changed Bedroom_Keiths_Closet_Contact_Sensor do |event|
  Bedroom_Keith_Closet_Light.ensure.command(event.state == ON)
end

changed Bedroom_Sarahs_Closet_Contact_Sensor, to: ON do |event|
  timers.cancel(event.item)
  Bedroom_Sarah_Closet_Light.ensure.on
end

changed Bedroom_Sarahs_Closet_Contact_Sensor, to: OFF do |event|
  after(30.seconds, id: event.item) { Bedroom_Sarah_Closet_Light.ensure.off }
end

# sarah right, keith left
updated(Bedroom_Hallway_Light_Scene_1, to: ZWave::Paddle::CLICK) { Bedroom_Table_Light_Switch.toggle }

updated(Bedroom_Hallway_Light_Scene_2, to: ZWave::Paddle::CLICK) { Bedroom_Sarah_Light_Switch.toggle }

updated(Bedroom_Hallway_Light_Scene_3, to: ZWave::Paddle::CLICK) do
  if Bedroom_Ceiling_Fan_Power.on?
    Bedroom_Ceiling_Fan_Speed.command(0)
  else
    Bedroom_Ceiling_Fan_Speed.command(3)
  end
end

updated(Bedroom_Hallway_Light_Scene_4, to: ZWave::Paddle::CLICK) { Bedroom_Hallway_Light_Switch.toggle }

updated(Bedroom_Hallway_Light_Scene_5, to: ZWave::Paddle::CLICK) { Bedroom_Ceiling_Fan_Light_Power.toggle }
