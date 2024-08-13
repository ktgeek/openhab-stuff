# frozen_string_literal: true

require "zwave"

changed(NanomoteQuad_Scene_1, to: 0) { Basement_Normal_Mode_Switch.on }

changed(NanomoteQuad_Scene_2, to: 0) { Basement_Stairs_Switch.toggle }

changed NanomoteQuad_Scene_3, to: 0 do
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

changed(NanomoteQuad_Scene_4, to: 0) { Basement_Movie_Mode_Switch.on }

changed(C_Basement_Scene_Top.members, to: ZWave::PADDLE_TWO_CLICKS) { Basement_Normal_Mode_Switch.on }

changed(C_Basement_Scene_Bottom.members, to: ZWave::PADDLE_TWO_CLICKS) { Basement_Movie_Mode_Switch.on }
