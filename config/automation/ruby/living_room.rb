# frozen_string_literal: true

require "zwave"

changed LivingRoom_Scene_Switch_Scenes.members do |event|
  next if event.null?

  event.item.update(NULL)
end

updated(LivingRoom_Scene_Switch_Scene_1, to: ZWave::Paddle::CLICK) { LivingRoom_Light_2_Color.toggle }

updated(LivingRoom_Scene_Switch_Scene_2, to: ZWave::Paddle::CLICK) { LivingRoom_Light_1_Color.toggle }

updated(LivingRoom_Scene_Switch_Scene_3, to: ZWave::Paddle::CLICK) { LivingRoom_Wall_Outlet_Switch.toggle }

updated(LivingRoom_Scene_Switch_Scene_4, to: ZWave::Paddle::CLICK) { Living_Room_Table_Light_Switch.toggle }
