# frozen_string_literal: true

require "zwave"

ensure_states!

# We don't know how long it takes to warm to temp like the nest did, so we're going to go for a half hour before we want
# temp
rule "weekday morning temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: "6am"
  run { FF_Thermostat_Min_Set_Point.command(73) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekday evening temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: "9:30pm"
  run { FF_Thermostat_Min_Set_Point.command(65) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend morning temp change" do
  every :saturday, :sunday, at: "7:00am"
  run { FF_Thermostat_Min_Set_Point.command(73) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend evening temp change" do
  every :saturday, :sunday, at: "10:15pm"
  run { FF_Thermostat_Min_Set_Point.command(65) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end
