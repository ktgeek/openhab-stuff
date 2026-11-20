# frozen_string_literal: true

require "sun_status"

rule "Groups Lights follow ON/OFF" do
  changed All_Hall_Lights.members

  run { |event| event.group.members.ensure.command(event.state) }
end

FRONT_YARD_LIGHT_SWITCHES = %w[porch-light-switch garage-outdoor-light-switch].map { |t| things["esphome:device:#{t}"] }
channel("button", thing: FRONT_YARD_LIGHT_SWITCHES, triggered: "single") { Front_Yard_Lights.toggle }

front_yard_morning_lights_on = lambda do
  Front_Yard_Lights.members.ensure.on
  Front_Yard_Outdoor_Decorations_Switch.ensure.on unless Holiday_Mode.state.blank?
end

rule "Morning Lights On For Rides", id: "morning_lights_on_for_rides" do
  cron "0 0 5 ? * TUE,THU"

  run { front_yard_morning_lights_on.call }

  only_if { Outdoor_Biking_Season.on? && SunStatus.down? }
end

rule "Morning lights on", id: "morning_lights_on" do
  cron "0 35 5 ? * MON-FRI"

  run { front_yard_morning_lights_on.call }

  only_if { SunStatus.down? }
end
