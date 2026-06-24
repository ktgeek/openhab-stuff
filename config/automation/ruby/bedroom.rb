# frozen_string_literal: true

require "zwave"
require "zigbee"

BEDROOM_REMOTES = [Bedroom_Table_Remote_Battery.thing, Bedroom_Sarah_Remote_Battery.thing].freeze

channel(%w[1_single 2_single 3_single], thing: BEDROOM_REMOTES) do |event|
  speed = 100 * (event.event[0].to_f / 3)

  Bedroom_CeilingFan_Speed.ensure.command(speed)
end

channel(%w[1_double 2_double 3_double], thing: BEDROOM_REMOTES) do
  Bedroom_CeilingFan_Speed.ensure.command(0)
end

channel("4_single", thing: BEDROOM_REMOTES) do |event|
  switch = items["Bedroom_#{event.thing.label.split[1]}Light_Switch"]
  switch&.toggle
end

channel("4_double", thing: BEDROOM_REMOTES) { Bedroom_CeilingFan_Light.toggle }

channel("4_hold", thing: BEDROOM_REMOTES.first) { Bedroom_SarahLight_Switch.toggle }

changed Bedroom_KeithsCloset_ContactSensor do |event|
  Bedroom_KeithsCloset_Light.ensure.command(event.state == ON)
end

changed Bedroom_SarahsCloset_ContactSensor, to: ON do |event|
  timers.cancel(event.item)
  Bedroom_SarahsCloset_Light.ensure.on
end

changed Bedroom_SarahsCloset_ContactSensor, to: OFF do |event|
  after(30.seconds, id: event.item) { Bedroom_SarahsCloset_Light.ensure.off }
end

# sarah right, keith left
updated(Bedroom_Hallway_Light_Scene_1, to: ZWave::Paddle::CLICK) { Bedroom_TableLight_Switch.toggle }

updated(Bedroom_Hallway_Light_Scene_2, to: ZWave::Paddle::CLICK) { Bedroom_SarahLight_Switch.toggle }

updated(Bedroom_Hallway_Light_Scene_3, to: ZWave::Paddle::CLICK) do
  if Bedroom_CeilingFan_Speed.on?
    Bedroom_CeilingFan_Speed.command(0)
  else
    Bedroom_CeilingFan_Speed.command(100)
  end
end

updated(Bedroom_Hallway_Light_Scene_4, to: ZWave::Paddle::CLICK) { Bedroom_Hallway_Light_Switch.toggle }

updated(Bedroom_Hallway_Light_Scene_5, to: ZWave::Paddle::CLICK) { Bedroom_CeilingFan_Light.toggle }
