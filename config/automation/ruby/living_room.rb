# frozen_string_literal: true

require "zwave"

channel("scene_1", thing: "mqtt:topic:26bcbec1ee:living_room_scene_switch", triggered: ZWave::PADDLE_CLICK) do
  LivingRoom_Light_2_Power.toggle
end

channel("scene_2", thing: "mqtt:topic:26bcbec1ee:living_room_scene_switch", triggered: ZWave::PADDLE_CLICK) do
  LivingRoom_Light_1_Power.toggle
end

channel("scene_3", thing: "mqtt:topic:26bcbec1ee:living_room_scene_switch", triggered: ZWave::PADDLE_CLICK) do
  LivingRoom_Wall_Outlet_Switch.toggle
end

channel("scene_4", thing: "mqtt:topic:26bcbec1ee:living_room_scene_switch", triggered: ZWave::PADDLE_CLICK) do
  Living_Room_Table_Light_Switch.toggle
end
