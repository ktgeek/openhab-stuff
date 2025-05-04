# frozen_string_literal: true

require "zwave"

ensure_states!

# We don't know how long it takes to warm to temp like the nest did, so we're going to go for a half hour before we want
# temp
rule "weekday morning first floor temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: "6am"
  run { FF_Thermostat_Min_Set_Point.command(73) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekday evening first floor temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: "9:30pm"
  run { FF_Thermostat_Min_Set_Point.command(65) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend morning first floor temp change" do
  every :saturday, :sunday, at: "7:00am"
  run { FF_Thermostat_Min_Set_Point.command(73) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend evening first floor temp change" do
  every :saturday, :sunday, at: "10:15pm"
  run { FF_Thermostat_Min_Set_Point.command(65) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

# Adding rules for the upstairs thermostat

rule "weekday morning upstairs temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: "5:15am"
  run { SF_Thermostat_Min_Set_Point.command(72) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekday evening upstairs temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: "9:30pm"
  run { SF_Thermostat_Min_Set_Point.command(66) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend morning upstairs temp change" do
  every :saturday, :sunday, at: "7:15am"
  run { SF_Thermostat_Min_Set_Point.command(72) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend evening upstairs temp change" do
  every :saturday, :sunday, at: "10:15pm"
  run { SF_Thermostat_Min_Set_Point.command(66) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end
