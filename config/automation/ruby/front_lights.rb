# frozen_string_literal: true

rule "Groups Lights follow ON/OFF" do
  changed Front_Yard_Lights.members, Backyard_Lights.members, All_Hall_Lights.members

  run { |event| event.group.members.ensure.command(event.state) }
end

rule "Morning Lights On For Rides", id: "morning_lights_on_for_rides" do
  cron "0 0 5 ? * TUE,THU"

  run do
    Front_Yard_Lights.ensure.on
    # For certain holidays we remove the garage switch from the Front Yard Lights group
    Garage_OutdoorLights_Switch.ensure.on unless Holiday_Mode.state.blank?
  end

  only_if { Outdoor_Biking_Season.on? && Sun_Status.state == "DOWN" }
end

rule "Morning lights on", id: "morning_lights_on" do
  cron "0 35 5 ? * MON-FRI"

  run do
    Front_Yard_Lights.members.ensure.on
    Garage_OutdoorLights_Switch.ensure.on unless Holiday_Mode.state.blank?
  end

  only_if { Sun_Status.state == "DOWN" }
end

