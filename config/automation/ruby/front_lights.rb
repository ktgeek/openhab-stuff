# frozen_string_literal: true

rule "Front Yard Lights follow ON" do
  changed Front_Yard_Lights.members

  run { |event| Front_Yard_Lights.members.ensure << event.state }
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
  cron "0 50 5 ? * MON-FRI"

  run do
    Front_Yard_Lights.members.ensure.on
    Garage_OutdoorLights_Switch.ensure.on unless Holiday_Mode.state.blank?
  end

  only_if { Sun_Status.state == "DOWN" }
end

rule "Morning lights off" do
  channel "astro:sun:local:rise#event", triggered: "END"

  run do
    Front_Yard_Lights.members.ensure.off
    Garage_OutdoorLights_Switch.ensure.off unless Holiday_Mode.state.blank?
  end
end
