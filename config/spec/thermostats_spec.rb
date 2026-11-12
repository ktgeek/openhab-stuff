# frozen_string_literal: true

require "zwave"

RSpec.describe "thermostats.rb" do
  let(:heat) { ZWave::Thermostat::Mode::HEAT }
  let(:setpoints) { { "FF_Thermostat" => FF_Thermostat_Heat_Setpoint, "SF_Thermostat" => SF_Thermostat_Heat_Setpoint } }
  let(:modes) { { "FF_Thermostat" => FF_Thermostat_Mode, "SF_Thermostat" => SF_Thermostat_Mode } }

  # The setpoint is set to something else first so that a command to the expected temperature is not skipped as a no-op
  before do
    setpoints.each_value { |setpoint| setpoint.update("50 °F") }
    Timecop.freeze(Time.local(2023, 7, 10, 12, 0, 0))
  end

  describe "scheduled temperature changes" do
    schedules = %w[sunday weekday friday saturday]

    { "FF_Thermostat" => { day: 73, night: 65 }, "SF_Thermostat" => { day: 73, night: 68 } }.each do |thermostat, temps|
      schedules.each do |schedule|
        temps.each do |period, temperature|
          context "when the #{period} starts for #{thermostat} on #{schedule}" do
            let(:rule) { rule_named("#{thermostat} #{schedule} #{heat} #{period} temp change") }

            it "sets the heat setpoint to #{temperature}" do
              modes[thermostat].update(heat)
              setpoints[thermostat].update("50 °F")
              rule.trigger(consider_conditions: true)

              expect(setpoints[thermostat].state.to_f).to eq temperature
            end
          end
        end
      end
    end

    context "when the thermostat is not in heat mode" do
      it "leaves the setpoint alone" do
        FF_Thermostat_Mode.update(ZWave::Thermostat::Mode::OFF)
        rule_named("FF_Thermostat weekday #{heat} day temp change").trigger(consider_conditions: true)

        expect(FF_Thermostat_Heat_Setpoint.state.to_f).to eq 50
      end
    end
  end

  describe "changing the thermostat mode to heat" do
    # [description, thermostat, time, expected temperature]; 2023-07-10 is a Monday
    {
      "FF on a weekday afternoon" => ["FF_Thermostat", Time.local(2023, 7, 10, 12, 0), 73],
      "FF on a weekday night" => ["FF_Thermostat", Time.local(2023, 7, 10, 23, 0), 65],
      "FF on a weekday after midnight" => ["FF_Thermostat", Time.local(2023, 7, 11, 3, 0), 65],
      "FF on a weekday before the day starts" => ["FF_Thermostat", Time.local(2023, 7, 11, 5, 59), 65],
      "FF on a Friday before the night starts" => ["FF_Thermostat", Time.local(2023, 7, 14, 22, 0), 73],
      "FF on a Saturday before the day starts" => ["FF_Thermostat", Time.local(2023, 7, 15, 7, 0), 65],
      "FF on a Sunday after the day starts" => ["FF_Thermostat", Time.local(2023, 7, 16, 7, 30), 73],
      "SF on a weekday after the day starts" => ["SF_Thermostat", Time.local(2023, 7, 10, 5, 30), 73],
      "SF on a weekday night" => ["SF_Thermostat", Time.local(2023, 7, 10, 22, 0), 68]
    }.each do |description, (thermostat, time, temperature)|
      it "sets #{temperature} for #{description}" do
        Timecop.freeze(time)
        modes[thermostat].update(heat)

        expect(setpoints[thermostat].state.to_f).to eq temperature
      end
    end

    it "leaves the setpoint alone when the mode is turned off" do
      FF_Thermostat_Mode.update(ZWave::Thermostat::Mode::OFF)

      expect(FF_Thermostat_Heat_Setpoint.state.to_f).to eq 50
    end

    it "leaves the setpoint alone for a mode with no schedule" do
      FF_Thermostat_Mode.update(ZWave::Thermostat::Mode::COOL)

      expect(FF_Thermostat_Heat_Setpoint.state.to_f).to eq 50
    end
  end
end
