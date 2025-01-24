# frozen_string_literal: true

require "zwave"
require "zigbee"

BEDROOM_REMOTES = %w[mqtt:topic:26bcbec1ee:bedroom_table_remote mqtt:topic:26bcbec1ee:bedroom_sarah_remote].freeze

updated Bedroom_Ceiling_Fan_Speed do |event|
  next unless (0..3).cover?(event.state)

  Bedroom_Ceiling_Fan_Power.update(event.state.positive?)
end

received_command(Bedroom_Ceiling_Fan_Power, command: OFF) { Bedroom_Ceiling_Fan_Speed.command(0) }

channel("action", thing: BEDROOM_REMOTES, triggered: %w[1_single 2_single 3_single]) do |event|
  Bedroom_Ceiling_Fan_Speed.command(event.event[0].to_i)
end

channel("action", thing: BEDROOM_REMOTES, triggered: %w[1_double 2_double 3_double]) do
  Bedroom_Ceiling_Fan_Speed.command(0)
end

channel("action", thing: BEDROOM_REMOTES, triggered: "4_single") do |event|
  switch = items["Bedroom_#{event.thing.label.split[1]}_Light_Switch"]
  switch&.toggle
end

channel("action", thing: BEDROOM_REMOTES, triggered: "4_double") { Bedroom_Ceiling_Fan_Light_Power.toggle }

channel("action", thing: BEDROOM_REMOTES.first, triggered: "4_hold") { Bedroom_Sarah_Light_Switch.toggle }

changed Bedroom_Keiths_Closet_Contact_Sensor do |event|
  Bedroom_Keith_Closet_Light.ensure.command(event.state == OPEN)
end

changed Bedroom_Sarahs_Closet_Contact_Sensor, to: OPEN do |event|
  timers.cancel(event.item)
  Bedroom_Sarah_Closet_Light.ensure.on
end

changed Bedroom_Sarahs_Closet_Contact_Sensor, to: CLOSED do |event|
  after(30.seconds, id: event.item) { Bedroom_Sarah_Closet_Light.ensure.off }
end

# sarah right, keith left
channel("scene_1", thing: "mqtt:topic:26bcbec1ee:162a22c6ce", triggered: ZWave::PADDLE_CLICK) do
  Bedroom_Table_Light_Switch.toggle
end

channel("scene_2", thing: "mqtt:topic:26bcbec1ee:162a22c6ce", triggered: ZWave::PADDLE_CLICK) do
  Bedroom_Sarah_Light_Switch.toggle
end

channel("scene_3", thing: "mqtt:topic:26bcbec1ee:162a22c6ce", triggered: ZWave::PADDLE_CLICK) do
  if Bedroom_Ceiling_Fan_Power.on?
    Bedroom_Ceiling_Fan_Speed.command(0)
  else
    Bedroom_Ceiling_Fan_Speed.command(3)
  end
end

channel("scene_4", thing: "mqtt:topic:26bcbec1ee:162a22c6ce", triggered: ZWave::PADDLE_CLICK) do
  Bedroom_Hallway_Light_Switch.toggle
end

channel("scene_5", thing: "mqtt:topic:26bcbec1ee:162a22c6ce", triggered: ZWave::PADDLE_CLICK) do
  Bedroom_Ceiling_Fan_Light_Power.toggle
end
