# frozen_string_literal: true

require "zwave"

updated Basement_NanomoteQuad_Scene_1, to: ZWave::Paddle::CLICK do
  Basement_Normal_Switch.on
end

updated Basement_NanomoteQuad_Scene_2, to: ZWave::Paddle::CLICK do
  Basement_Stairs_Switch.toggle
end

updated Basement_NanomoteQuad_Scene_3, to: ZWave::Paddle::CLICK do
  ensure_states do
    if Basement_TheaterLights.state < 100 || Basement_BarLights.state < 100
      Basement_TheaterLights.command(100)
      Basement_BarLights.command(100)
    else
      Basement_TheaterLights.off
      Basement_BarLights.off
    end
  end
end

updated Basement_NanomoteQuad_Scene_4, to: ZWave::Paddle::CLICK do
  Basement_Movie_Switch.on
end

updated(Basement_Scenes_1.members, to: ZWave::Paddle::TWO_CLICKS) { Basement_Normal_Switch.on }
updated(Basement_Scenes_2.members, to: ZWave::Paddle::TWO_CLICKS) { Basement_Movie_Switch.on }
