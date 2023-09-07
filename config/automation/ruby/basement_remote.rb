# frozen_string_literal: true

require "homeseer"

rule "when the basement remote is used" do
  updated NanomoteQuad_Scene

  run do |event|
    case event.state
    when 1.0
      Basement_Normal_Mode_Switch.on
    when 2.0
      Basement_Stairs_Switch.on? ? Basement_Stairs_Switch.off : Basement_Stairs_Switch.on
    when 3.0
      if Basement_Room_Theater_Lights.state < 100 || Basement_Room_Bar_Lights.state < 100
        Basement_Room_Theater_Lights.ensure << 100
        Basement_Room_Bar_Lights.ensure << 100
      else
        Basement_Room_Theater_Lights.ensure.off
        Basement_Room_Bar_Lights.ensure.off
      end
    when 4.0
      Basement_Movie_Mode_Switch.on
    end
  end
end

rule "when the basement theater switches have a scene change" do
  updated C_Basement_Scene.members

  run do |event|
    case event.state
    when Homeseer::PADDLE_UP_TWO_CLICKS
      Basement_Normal_Mode_Switch.on
    when Homeseer::PADDLE_DOWN_TWO_CLICKS
      Basement_Movie_Mode_Switch.on
    end
  end
end
