# frozen_string_literal: true

require "zwave"

ensure_states!

TIMING = {
  FF_Thermostat_Mode => {
    WEEK: { day_start: "6am", night_start: "9:30pm" },
    WEEKEND: { day_start: "7:00am", night_start: "10:15pm" }
  },
  SF_Thermostat_Mode => {
    WEEK: { day_start: "5:15am", night_start: "9:30pm" },
    WEEKEND: { day_start: "7:15am", night_start: "10:15pm" }
  }
}.freeze

# We don't know how long it takes to warm to temp like the nest did, so we're going to go for a half hour before we want
# temp
rule "weekday morning first floor temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: TIMING.dig(FF_Thermostat_Mode, :WEEK, :day_start)
  run { FF_Thermostat_Min_Set_Point.command(73) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekday evening first floor temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: TIMING.dig(FF_Thermostat_Mode, :WEEK, :night_start)
  run { FF_Thermostat_Min_Set_Point.command(65) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend morning first floor temp change" do
  every :saturday, :sunday, at: TIMING.dig(FF_Thermostat_Mode, :WEEKEND, :day_start)
  run { FF_Thermostat_Min_Set_Point.command(73) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend evening first floor temp change" do
  every :saturday, :sunday, at: TIMING.dig(FF_Thermostat_Mode, :WEEKEND, :night_start)
  run { FF_Thermostat_Min_Set_Point.command(65) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

# Adding rules for the upstairs thermostat

rule "weekday morning upstairs temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: TIMING.dig(SF_Thermostat_Mode, :WEEK, :day_start)
  run { SF_Thermostat_Min_Set_Point.command(73) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekday evening upstairs temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: TIMING.dig(SF_Thermostat_Mode, :WEEK, :night_start)
  run { SF_Thermostat_Min_Set_Point.command(68) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend morning upstairs temp change" do
  every :saturday, :sunday, at: TIMING.dig(SF_Thermostat_Mode, :WEEKEND, :day_start)
  run { SF_Thermostat_Min_Set_Point.command(73) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend evening upstairs temp change" do
  every :saturday, :sunday, at: TIMING.dig(SF_Thermostat_Mode, :WEEKEND, :night_start)
  run { SF_Thermostat_Min_Set_Point.command(68) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

changed(FF_Thermostat_Mode, SF_Thermostat_Mode, to: ZWave::Thermostat::Mode::HEAT) do |event|
  time = Time.now
  times = TIMING.dig(event.item, (time.weekend? ? :WEEKEND : :WEEK))

  case time
  when between(times[:day_start]..times[:night_start])
    FF_Thermostat_Min_Set_Point.command(73)
  when between(times[:night_start]..times[:day_start])
    FF_Thermostat_Min_Set_Point.command(65)
  end
end
