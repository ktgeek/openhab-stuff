# frozen_string_literal: true

require "zwave"

channel("scene_1", thing: "mqtt:topic:26bcbec1ee:f7c5f297b6", triggered: ZWave::PADDLE_CLICK) do
  Basement_Normal_Mode_Switch.on
end

channel("scene_2", thing: "mqtt:topic:26bcbec1ee:f7c5f297b6", triggered: ZWave::PADDLE_CLICK) do
  Basement_Stairs_Switch.toggle
end

channel("scene_3", thing: "mqtt:topic:26bcbec1ee:f7c5f297b6", triggered: ZWave::PADDLE_CLICK) do
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

channel("scene_4", thing: "mqtt:topic:26bcbec1ee:f7c5f297b6", triggered: ZWave::PADDLE_CLICK) do
  Basement_Movie_Mode_Switch.on
end

changed(C_Basement_Scene_Top.members, to: ZWave::PADDLE_TWO_CLICKS) { Basement_Normal_Mode_Switch.on }

changed(C_Basement_Scene_Bottom.members, to: ZWave::PADDLE_TWO_CLICKS) { Basement_Movie_Mode_Switch.on }
