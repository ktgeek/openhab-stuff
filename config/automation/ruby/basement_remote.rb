# frozen_string_literal: true

require "zwave"

changed C_Basement_NanomoteQuad_Scenes.members do |event|
  next if event.null?

  event.item.update(NULL)
end

updated C_Basement_NanomoteQuad_Scene_1, to: ZWave::Paddle::CLICK do
  C_Basement_Normal_Switch.on
end

updated C_Basement_NanomoteQuad_Scene_2, to: ZWave::Paddle::CLICK do
  Basement_Stairs_Switch.toggle
end

updated C_Basement_NanomoteQuad_Scene_3, to: ZWave::Paddle::CLICK do
  ensure_states do
    if Basement_Room_Theater_Lights.state < 100 || Basement_Room_Bar_Lights.state < 100
      Basement_Room_Theater_Lights.command(100)
      Basement_Room_Bar_Lights.command(100)
    else
      Basement_Room_Theater_Lights.off
      Basement_Room_Bar_Lights.off
    end
  end
end

updated C_Basement_NanomoteQuad_Scene_4, to: ZWave::Paddle::CLICK do
  C_Basement_Movie_Switch.on
end

BASEMENT_SCENES = C_Basement_Scenes.members.map(&:thing)
channel("scene_1", thing: BASEMENT_SCENES, triggered: ZWave::Paddle::TWO_CLICKS) { C_Basement_Normal_Switch.on }
channel("scene_2", thing: BASEMENT_SCENES, triggered: ZWave::Paddle::TWO_CLICKS) { C_Basement_Movie_Switch.on }
