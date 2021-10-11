# frozen_string_literal: true

require 'openhab'

rule "Front Yard Lights follow ON" do
  changed Front_Yard_Lights.members

  run { |event| Front_Yard_Lights.each { |i| i << event.state unless i.state == event.state } }
end

rule "Morning Lights On For Rides" do
  cron "0 0 5 ? * TUE,THU"

  # run { Front_Yard_Lights.on if Sun_Status == "DOWN" && Front_Yard_Lights.off? }
  run do
    if Sun_Status == "DOWN"
      Front_Yard_Lights.on unless Front_Yard_Lights.on?
      Garage_OutdoorLights_Switch.on unless Garage_OutdoorLights_Switch.on?
    end
  end
end

rule "Morning lights on" do
  cron "0 50 5 ? * MON-FRI"

  run do
    if Sun_Status == "DOWN"
      Front_Yard_Lights.on unless Front_Yard_Lights.on?
      Garage_OutdoorLights_Switch.on unless Garage_OutdoorLights_Switch.on?
    end
  end
end

rule "Morning lights off" do
  channel "astro:sun:local:rise#event", triggered: "END"

  run do
    Front_Yard_Lights.off unless Front_Yard_Lights.off?
    Garage_OutdoorLights_Switch.off unless Garage_OutdoorLights_Switch.off?
  end
end
