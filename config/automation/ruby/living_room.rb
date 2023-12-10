# frozen_string_literal: true

require "zwave"

updated LivingRoom_Scene_Switch_Scene_1, to: ZWave::PADDLE_CLICK do
  LivingRoom_Light_2_Power.toggle
end

updated LivingRoom_Scene_Switch_Scene_2, to: ZWave::PADDLE_CLICK do
  LivingRoom_Light_1_Power.toggle
end

updated LivingRoom_Scene_Switch_Scene_3, to: ZWave::PADDLE_CLICK do
  LivingRoom_Wall_Outlet_Switch.toggle
end

updated LivingRoom_Scene_Switch_Scene_4, to: ZWave::PADDLE_CLICK do
  LivingRoom_Table_Light_Switch.toggle
end
