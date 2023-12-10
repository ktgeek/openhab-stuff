# frozen_string_literal: true

require "zwave"

changed NanomoteQuad_Scene_1, to: 0 do
  Basement_Normal_Mode_Switch.on
end

changed NanomoteQuad_Scene_2, to: 0 do
  Basement_Stairs_Switch.on? ? Basement_Stairs_Switch.off : Basement_Stairs_Switch.on
end

changed NanomoteQuad_Scene_3, to: 0 do
  if Basement_Room_Theater_Lights.state < 100 || Basement_Room_Bar_Lights.state < 100
    Basement_Room_Theater_Lights.ensure << 100
    Basement_Room_Bar_Lights.ensure << 100
  else
    Basement_Room_Theater_Lights.ensure.off
    Basement_Room_Bar_Lights.ensure.off
  end
end

changed NanomoteQuad_Scene_4, to: 0 do
  Basement_Movie_Mode_Switch.on
end

changed C_Basement_Scene_Top.members, to: ZWave::PADDLE_TWO_CLICKS do
  Basement_Normal_Mode_Switch.on
end

changed C_Basement_Scene_Bottom.members, to: ZWave::PADDLE_TWO_CLICKS do
  Basement_Movie_Mode_Switch.on
end
