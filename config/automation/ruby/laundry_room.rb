# frozen_string_literal: true

require "zwave"

rule "when the laundry room door opens" do
  changed Laundry_Room_Door_Contact, to: OPEN

  run { Side_Yard_Light_Power.ensure.on }

  only_if { Sun_Status.state == "DOWN" }
end

changed(Laundry_Room_Door_Contact, to: CLOSED) { Side_Yard_Light_Power.ensure.off }

channel("mqtt:topic:26bcbec1ee:7f0a376172:scene_1", triggered: ZWave::Paddle::CLICK) { Side_Yard_Light_Power.ensure.on }

channel("mqtt:topic:26bcbec1ee:7f0a376172:scene_2", triggered: ZWave::Paddle::CLICK) do
  Side_Yard_Light_Power.ensure.off
end
