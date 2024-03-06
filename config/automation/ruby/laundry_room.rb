# frozen_string_literal: true

require "zwave"

rule "when the laundry room door opens" do
  changed Laundry_Room_Door_Contact, to: OPEN

  run { Side_Yard_Light_Power.ensure.command(ON) }

  only_if { Sun_Status.state == "DOWN" }
end

rule "when the laundry room door closes" do
  changed Laundry_Room_Door_Contact, to: CLOSED

  run { Side_Yard_Light_Power.ensure.command(OFF) }
end

updated(Side_Yard_Lights_Scene_Number_Top, to: ZWave::PADDLE_CLICK) { Side_Yard_Light_Power.ensure.command(ON) }

updated(Side_Yard_Lights_Scene_Number_Bottom, to: ZWave::PADDLE_CLICK) { Side_Yard_Light_Power.ensure.command(OFF) }
