# frozen_string_literal: true

require "zwave"

ensure_states!

TEMP_SETTINGS = {
  FF_Thermostat => {
    temps: {
      ZWave::Thermostat::Mode::HEAT => { day: 73, night: 65 }
    },
    schedule: [
      { name: "weekday", days: %i[monday tuesday wednesday thursday friday], day_start: "6am", night_start: "9:30pm",
        mode: ZWave::Thermostat::Mode::HEAT },
      { name: "weekend", days: %i[saturday sunday], day_start: "7:00am", night_end: "10:15pm",
        mode: ZWave::Thermostat::Mode::HEAT }
    ]
  },
  SF_Thermostat => {
    temps: {
      ZWave::Thermostat::Mode::HEAT => { day: 73, night: 68 }
    },
    schedule: [
      { name: "weekday", days: %i[monday tuesday wednesday thursday friday], day_start: "5:15am",
        night_start: "9:30pm", mode: ZWave::Thermostat::Mode::HEAT },
      { name: "weekend", days: %i[saturday sunday], day_start: "7:15am", night_start: "10:15pm",
        mode: ZWave::Thermostat::Mode::HEAT }
    ]
  }
}.freeze

TEMP_SETTINGS.each do |thermostat, tsettings|
  thermostat_name = thermostat.name
  set_point = items["#{thermostat_name}_Min_Set_Point"]
  thermostat_mode = items["#{thermostat_name}_Mode"]

  tsettings[:schedule].each do |schedule|
    temps = tsettings.dig(:temps, schedule[:mode])

    rule "#{thermostat_name} #{schedule[:name]} day temp change" do
      every(*schedule[:days], at: schedule[:day_start])
      run { set_point.command(temps[:day]) }
      only_if { thermostat_mode.state.to_i == schedule[:mode] }
    end

    rule "#{thermostat_name} #{schedule[:name]} night temp change" do
      every(*schedule[:days], at: schedule[:night_start])
      run { set_point.command(temps[:night]) }
      only_if { thermostat_mode.state.to_i == schedule[:mode] }
    end
  end
end

changed(FF_Thermostat_Mode, SF_Thermostat_Mode) do |event|
  thermostat = event.item.groups.first
  tsetting = TEMP_SETTINGS[thermostat]
  mode = event.state.to_i

  time = Time.now
  day_of_week = time.strftime("%A").downcase!.to_sym

  schedule = tsetting[:schedule].find { |s| s[:mode] == mode && s[:days].include?(day_of_week) }

  next unless schedule

  set_point = items["#{thermostat.name}_Min_Set_Point"]
  temps = tsetting.dig(:temps, mode)

  case time
  when between(schedule[:day_start]..schedule[:night_start])
    set_point.command(temps[:day])
  when between(schedule[:night_start]..schedule[:day_start])
    set_point.command(temps[:night])
  end
end
