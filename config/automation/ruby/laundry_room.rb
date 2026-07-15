# frozen_string_literal: true

require "sun_status"
require "zwave"

rule "when the laundry room door opens" do
  changed LaundryRoom_Door_Contact, to: ON

  run { SideYard_Light_Color.ensure.on }

  only_if { Sun_Status.state == SunStatus::DOWN }
end

changed(LaundryRoom_Door_Contact, to: OFF) { SideYard_Light_Color.ensure.off }

updated(SideYard_Lights_Scene_1, to: ZWave::Paddle::CLICK) { SideYard_Light_Color.ensure.on }

updated(SideYard_Lights_Scene_2, to: ZWave::Paddle::CLICK) { SideYard_Light_Color.ensure.off }
