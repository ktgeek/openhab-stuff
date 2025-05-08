# frozen_string_literal: true

require "zwave"

ensure_states!

TIMING = {
  FF_Thermostat => {
    day_temp: 73,
    night_temp: 65,
    week: { day_start: "6am", night_start: "9:30pm" },
    weekend: { day_start: "7:00am", night_start: "10:15pm" }
  },
  SF_Thermostat => {
    day_temp: 73,
    night_temp: 68,
    week: { day_start: "5:15am", night_start: "9:30pm" },
    weekend: { day_start: "7:15am", night_start: "10:15pm" }
  }
}.freeze

# We don't know how long it takes to warm to temp like the nest did, so we're going to go for a half hour before we want
# temp
rule "weekday morning first floor temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: TIMING.dig(FF_Thermostat, :week, :day_start)
  run { FF_Thermostat_Min_Set_Point.command(TIMING.dig(FF_Thermostat, :day_temp)) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekday evening first floor temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: TIMING.dig(FF_Thermostat, :week, :night_start)
  run { FF_Thermostat_Min_Set_Point.command(TIMING.dig(FF_Thermostat, :night_temp)) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend morning first floor temp change" do
  every :saturday, :sunday, at: TIMING.dig(FF_Thermostat, :weekend, :day_start)
  run { FF_Thermostat_Min_Set_Point.command(TIMING.dig(FF_Thermostat, :day_temp)) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend evening first floor temp change" do
  every :saturday, :sunday, at: TIMING.dig(FF_Thermostat, :weekend, :night_start)
  run { FF_Thermostat_Min_Set_Point.command(TIMING.dig(FF_Thermostat, :night_temp)) }
  only_if { FF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

# Adding rules for the upstairs thermostat

rule "weekday morning upstairs temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: TIMING.dig(SF_Thermostat, :week, :day_start)
  run { SF_Thermostat_Min_Set_Point.command(TIMING.dig(SF_Thermostat, :day_temp)) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekday evening upstairs temp change" do
  every :monday, :tuesday, :wednesday, :thursday, :friday, at: TIMING.dig(SF_Thermostat, :week, :night_start)
  run { SF_Thermostat_Min_Set_Point.command(TIMING.dig(SF_Thermostat, :night_temp)) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend morning upstairs temp change" do
  every :saturday, :sunday, at: TIMING.dig(SF_Thermostat, :weekend, :day_start)
  run { SF_Thermostat_Min_Set_Point.command(TIMING.dig(SF_Thermostat, :day_temp)) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

rule "weekend evening upstairs temp change" do
  every :saturday, :sunday, at: TIMING.dig(SF_Thermostat, :weekend, :night_start)
  run { SF_Thermostat_Min_Set_Point.command(TIMING.dig(SF_Thermostat, :night_temp)) }
  only_if { SF_Thermostat_Mode.state == ZWave::Thermostat::Mode::HEAT }
end

changed(FF_Thermostat_Mode, SF_Thermostat_Mode, to: ZWave::Thermostat::Mode::HEAT) do |event|
  item = event.item
  set_point = items["#{item.groups.first.name}_Min_Set_Point"]

  time = Time.now
  times = TIMING.dig(item, (time.weekend? ? :weekend : :week))

  case time
  when between(times[:day_start]..times[:night_start])
    set_point.command(TIMING.dig(event.item, :day_temp))
  when between(times[:night_start]..times[:day_start])
    set_point.command(TIMING.dig(event.item, :night_temp))
  end
end
