# frozen_string_literal: true

require "zwave"
require "time_helpers"

ensure_states!

TEMP_SETTINGS = {
  FF_Thermostat => {
    ZWave::Thermostat::Mode::HEAT => {
      temps: { day: 73, night: 65 },
      schedule: [
        {
          name: "sunday",
          days: %i[sunday],
          day_start: "7:15am",
          night_start: "9:30pm"
        },
        {
          name: "weekday",
          days: %i[monday tuesday wednesday thursday],
          day_start: "6am",
          night_start: "9:30pm"
        },
        {
          name: "friday",
          days: %i[friday],
          day_start: "6am",
          night_start: "10:15pm"
        },
        {
          name: "saturday",
          days: %i[saturday],
          day_start: "7:15am",
          night_start: "10:15pm"
        }
      ]
    }
  },
  SF_Thermostat => {
    ZWave::Thermostat::Mode::HEAT => {
      temps: { day: 73, night: 68 },
      schedule: [
        {
          name: "sunday",
          days: %i[sunday],
          day_start: "7:00am",
          night_start: "9:30pm"
        },
        {
          name: "weekday",
          days: %i[monday tuesday wednesday thursday],
          day_start: "5:15am",
          night_start: "9:30pm"
        },
        {
          name: "friday",
          days: %i[friday],
          day_start: "5:15am",
          night_start: "10:15pm"
        },
        {
          name: "saturday",
          days: %i[saturday],
          day_start: "7:00am",
          night_start: "10:15pm"
        }
      ]
    }
  }
}.freeze

TEMP_SETTINGS.each do |thermostat, tsettings|
  thermostat_name = thermostat.name
  set_point = items["#{thermostat_name}_Min_Set_Point"]
  thermostat_mode = items["#{thermostat_name}_Mode"]

  tsettings.each do |mode, mode_settings|
    mode_settings[:schedule].each do |schedule|
      temps = mode_settings[:temps]

      rule "#{thermostat_name} #{schedule[:name]} #{mode} day temp change" do
        every(*schedule[:days], at: schedule[:day_start])
        run { set_point.command(temps[:day]) }
        only_if { thermostat_mode.state.to_i == mode }
      end

      rule "#{thermostat_name} #{schedule[:name]} #{mode} night temp change" do
        every(*schedule[:days], at: schedule[:night_start])
        run { set_point.command(temps[:night]) }
        only_if { thermostat_mode.state.to_i == mode }
      end
    end
  end
end

changed(FF_Thermostat_Mode, SF_Thermostat_Mode) do |event|
  next if event.state.to_i == ZWave::Thermostat::Mode::OFF

  thermostat = event.item.groups.first
  mode = event.state.to_i
  mode_setting = TEMP_SETTINGS.dig(thermostat, mode)

  next unless mode_setting

  time = Time.now
  schedule = mode_setting[:schedule]&.find { |s| s[:days].include?(TimeHelpers::DAY_OF_WEEK[time.wday]) }

  next unless schedule

  set_point = items["#{thermostat.name}_Min_Set_Point"]
  temps = mode_setting[:temps]

  case time
  when between(schedule[:day_start]..schedule[:night_start])
    set_point.command(temps[:day])
  when between(schedule[:night_start]..schedule[:day_start])
    set_point.command(temps[:night])
  end
end
