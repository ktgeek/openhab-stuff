# frozen_string_literal: true

require "zwave"

rule "when the laundry room door opens" do
  changed Laundry_Room_Door_Contact, to: OPEN

  run { Side_Yard_Light_Power.ensure.on }

  only_if { Sun_Status.state == "DOWN" }
end

changed(Laundry_Room_Door_Contact, to: CLOSED) { Side_Yard_Light_Power.ensure.off }

updated(Side_Yard_Lights_Scene_1, to: ZWave::Paddle::CLICK) { Side_Yard_Light_Power.ensure.on }

updated(Side_Yard_Lights_Scene_2, to: ZWave::Paddle::CLICK) { Side_Yard_Light_Power.ensure.off }
