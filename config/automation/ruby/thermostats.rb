# frozen_string_literal: true

require "zwave"

ensure_states!

TEMP_SETTINGS = {
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

TEMP_SETTINGS.each do |thermostat, tsettings|
  name = thermostat.name
  set_point = items["#{name}_Min_Set_Point"]
  mode = items["#{name}_Mode"]

  rule "weekday morning #{name} temp change" do
    every :monday, :tuesday, :wednesday, :thursday, :friday, at: tsettings.dig(:week, :day_start)
    run { set_point.command(tsettings[:day_temp]) }
    only_if { mode.state == ZWave::Thermostat::Mode::HEAT }
  end

  rule "weekday evening #{name} temp change" do
    every :monday, :tuesday, :wednesday, :thursday, :friday, at: tsettings.dig(:week, :night_start)
    run { set_point.command(tsettings[:night_temp]) }
    only_if { mode.state == ZWave::Thermostat::Mode::HEAT }
  end

  rule "weekend morning #{name} temp change" do
    every :saturday, :sunday, at: tsettings.dig(:weekend, :day_start)
    run { set_point.command(tsettings[:day_temp]) }
    only_if { mode.state == ZWave::Thermostat::Mode::HEAT }
  end

  rule "weekend evening #{name} temp change" do
    every :saturday, :sunday, at: tsettings.dig(:weekend, :night_start)
    run { set_point.command(tsettings[:night_temp]) }
    only_if { mode.state == ZWave::Thermostat::Mode::HEAT }
  end
end

changed(FF_Thermostat_Mode, SF_Thermostat_Mode, to: ZWave::Thermostat::Mode::HEAT) do |event|
  item = event.item
  set_point = items["#{item.groups.first.name}_Min_Set_Point"]

  time = Time.now
  times = TEMP_SETTINGS.dig(item, (time.weekend? ? :weekend : :week))

  case time
  when between(times[:day_start]..times[:night_start])
    set_point.command(TEMP_SETTINGS.dig(item, :day_temp))
  when between(times[:night_start]..times[:day_start])
    set_point.command(TEMP_SETTINGS.dig(item, :night_temp))
  end
end
