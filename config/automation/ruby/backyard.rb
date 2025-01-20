# frozen_string_literal: true

require "zwave"

updated(Kitchen_Backyard_Lights_Scene_1, FamilyRoom_Backyard_Lights_Scene_1, to: ZWave::PADDLE_CLICK) do
  Backyard_Lights_Power.ensure.on
end

updated(Kitchen_Backyard_Lights_Scene_2, FamilyRoom_Backyard_Lights_Scene_2, to: ZWave::PADDLE_CLICK) do
  Backyard_Lights_Power.ensure.off
end
