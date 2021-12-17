# frozen_string_literal: true

require "openhab"

rule "Front Yard Lights follow ON" do
  changed Front_Yard_Lights.members

  run { |event| Front_Yard_Lights.members.ensure << event.state }
end

rule "Morning Lights On For Rides" do
  cron "0 0 5 ? * TUE,THU"

  run do
    if Sun_Status == "DOWN"
      Front_Yard_Lights.ensure.on
      Garage_OutdoorLights_Switch.ensure.on unless Holiday_Mode.blank?
    end
  end

  only_if { Outdoor_Biking_Season.on? }
end

rule "Morning lights on" do
  cron "0 50 5 ? * MON-FRI"

  run do
    if Sun_Status == "DOWN"
      Front_Yard_Lights.members.ensure.on
      Garage_OutdoorLights_Switch.ensure.on unless Holiday_Mode.blank?
    end
  end
end

rule "Morning lights off" do
  channel "astro:sun:local:rise#event", triggered: "END"

  run do
    Front_Yard_Lights.members.ensure.off
    Garage_OutdoorLights_Switch.ensure.off unless Holiday_Mode.blank?
  end
end
