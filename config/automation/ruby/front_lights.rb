# frozen_string_literal: true

rule "Groups Lights follow ON/OFF" do
  changed All_Hall_Lights.members

  run { |event| event.group.members.ensure.command(event.state) }
end

updated Garage_OutdoorLights_Button_Action, FrontDoor_Lights_Button_Action, to: "SINGLE" do
  Front_Yard_Lights.toggle
end

rule "Morning Lights On For Rides", id: "morning_lights_on_for_rides" do
  cron "0 0 5 ? * TUE,THU"

  run do
    Front_Yard_Lights.members.ensure.on

    Front_Yard_Outdoor_Decorations_Switch.ensure.on unless Holiday_Mode.state.blank?
  end

  only_if { Outdoor_Biking_Season.on? && Sun_Status.state == "DOWN" }
end

rule "Morning lights on", id: "morning_lights_on" do
  cron "0 35 5 ? * MON-FRI"

  run do
    Front_Yard_Lights.members.ensure.on
    Front_Yard_Outdoor_Decorations_Switch.ensure.on unless Holiday_Mode.state.blank?
  end

  only_if { Sun_Status.state == "DOWN" }
end
