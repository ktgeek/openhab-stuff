# frozen_string_literal: true

require "homeseer"

changed NanomoteQuad_Scene_1, to: 0 do
  Basement_Normal_Mode_Switch.on
  NanomoteQuad_Scene_1.update(NULL)
end

changed NanomoteQuad_Scene_2, to: 0 do
  Basement_Stairs_Switch.on? ? Basement_Stairs_Switch.off : Basement_Stairs_Switch.on
  NanomoteQuad_Scene_2.update(NULL)
end

changed NanomoteQuad_Scene_3, to: 0 do
  if Basement_Room_Theater_Lights.state < 100 || Basement_Room_Bar_Lights.state < 100
    Basement_Room_Theater_Lights.ensure << 100
    Basement_Room_Bar_Lights.ensure << 100
  else
    Basement_Room_Theater_Lights.ensure.off
    Basement_Room_Bar_Lights.ensure.off
  end
  NanomoteQuad_Scene_3.update(NULL)
end

changed NanomoteQuad_Scene_4, to: 0 do
  Basement_Movie_Mode_Switch.on
  NanomoteQuad_Scene_4.update(NULL)
end

changed C_Basement_Scene_Top.members, to: Homeseer::PADDLE_TWO_CLICKS do |event|
  Basement_Normal_Mode_Switch.on
  event.group.members.update(NULL)
end

changed C_Basement_Scene_Bottom.members, to: Homeseer::PADDLE_TWO_CLICKS do |event|
  Basement_Movie_Mode_Switch.on
  event.group.members.update(NULL)
end
