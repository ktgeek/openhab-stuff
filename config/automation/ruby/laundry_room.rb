# frozen_string_literal: true

rule "when the laundry room door opens" do
  changed Laundry_Room_Door_Contact, to: OPEN

  run { Side_Yard_Lights_Switch.ensure.on }

  only_if { Sun_Status.state == "DOWN" }
end

rule "when the laundry room door closes" do
  changed Laundry_Room_Door_Contact, to: CLOSED

  run { Side_Yard_Lights_Switch.ensure.off }
end
