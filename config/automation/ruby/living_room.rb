# frozen_string_literal: true

require "zwave"

LIVING_ROOM_SCENE_SWITCH = "mqtt:topic:26bcbec1ee:living_room_scene_switch"

channel("scene_1", thing: LIVING_ROOM_SCENE_SWITCH, triggered: ZWave::Paddle::CLICK) { LivingRoom_Light_2_Color.toggle }

channel("scene_2", thing: LIVING_ROOM_SCENE_SWITCH, triggered: ZWave::Paddle::CLICK) { LivingRoom_Light_1_Color.toggle }

channel("scene_3", thing: LIVING_ROOM_SCENE_SWITCH, triggered: ZWave::Paddle::CLICK) do
  LivingRoom_Wall_Outlet_Switch.toggle
end

channel("scene_4", thing: LIVING_ROOM_SCENE_SWITCH, triggered: ZWave::Paddle::CLICK) do
  Living_Room_Table_Light_Switch.toggle
end
