# frozen_string_literal: true

RSpec.describe "office.rb" do
  describe "Zoom LED" do
    context "when a Zoom meeting starts" do
      before do
        Office_DoorLED_Fade.update(ON)
        Office_Bugg_Zoom.update(ON)
      end

      it "turns the door LED fade off" do
        expect(Office_DoorLED_Fade).to be_off
      end

      it "sets the door LED to a single color effect" do
        expect(Office_DoorLED_LightEffects.state).to eq Esphome::LC5050C::Effects::SINGLE_COLOR
      end

      it "sets the door LED to red" do
        expect(Office_DoorLED_Color.state).to eq Color::RED
      end
    end

    context "when a Zoom meeting ends and the door LED was on before it" do
      before do
        Office_DoorLED_Color.update(Color::WARM_WHITE)
        Office_DoorLED_LightEffects.update("Rainbow")
        Office_DoorLED_Fade.update(ON)
        Office_DoorLED_Palette.update("Sunset")
        Office_DoorLED_Speed.update(50)
        Office_Bugg_Zoom.update(ON)
        # The device reports a new palette and speed of its own when the meeting changes the effect and color
        Office_DoorLED_Palette.update("Default")
        Office_DoorLED_Speed.update(10)
        Office_Bugg_Zoom.update(OFF)
      end

      it "restores the color" do
        expect(Office_DoorLED_Color.state).to eq Color::WARM_WHITE
      end

      it "restores the light effect" do
        expect(Office_DoorLED_LightEffects.state.to_s).to eq "Rainbow"
      end

      it "restores the fade" do
        expect(Office_DoorLED_Fade).to be_on
      end

      it "restores the palette" do
        expect(Office_DoorLED_Palette.state.to_s).to eq "Sunset"
      end

      it "restores the speed" do
        expect(Office_DoorLED_Speed.state.to_i).to eq 50
      end
    end

    context "when a Zoom meeting ends and the door LED was off before it" do
      before do
        Office_Bugg_Zoom.update(ON)
        Office_Bugg_Zoom.update(OFF)
      end

      it "turns the door LED off" do
        expect(Office_DoorLED_Color).to be_off
      end
    end
  end

  describe "office presence" do
    context "when someone enters the office" do
      before do
        Office_Lights_Switch.update(OFF)
        Office_Monitor_LED.update(OFF)
        Office_Presence_Sensor.update(ON)
      end

      it "turns on the office lights" do
        expect(Office_Lights_Switch).to be_on
      end

      it "turns on the monitor LEDs" do
        expect(Office_Monitor_LED).to be_on
      end
    end

    context "when the office is empty" do
      before do
        Office_Lights_Switch.update(ON)
        Office_Monitor_LED.update(ON)
        Office_Presence_Sensor.update(OFF)
      end

      it "turns off the office lights" do
        expect(Office_Lights_Switch).to be_off
      end

      it "turns off the monitor LEDs" do
        expect(Office_Monitor_LED).to be_off
      end
    end
  end

  describe "office window decorations" do
    # Changing Sun_Status also runs entrance_lights.rb, and holiday.rb reacts to it once a holiday is set, so the sun
    # is set first
    before do
      Entrance_IgnoreLuminance_Switch.update(ON)
      Sun_Status.update(sun)
      Holiday_Mode.update(holiday)
    end

    let(:sun) { SunStatus::UP }
    let(:holiday) { Holidays::CHRISTMAS }

    context "when someone enters the office during the day at Christmas" do
      it "turns on the window decorations" do
        Office_Presence_Sensor.update(ON)

        expect(Office_WindowDecorations_Switch).to be_on
      end
    end

    context "when someone enters the office at night at Christmas" do
      let(:sun) { SunStatus::DOWN }

      it "leaves the window decorations off" do
        Office_Presence_Sensor.update(ON)

        expect(Office_WindowDecorations_Switch).not_to be_on
      end
    end

    context "when someone enters the office during the day on another holiday" do
      let(:holiday) { Holidays::HALLOWEEN }

      it "leaves the window decorations off" do
        Office_Presence_Sensor.update(ON)

        expect(Office_WindowDecorations_Switch).not_to be_on
      end
    end

    context "when the office empties during the day at Christmas with the Christmas lights off" do
      before do
        Office_WindowDecorations_Switch.update(ON)
        Office_Presence_Sensor.update(OFF)
      end

      it "turns off the window decorations" do
        expect(Office_WindowDecorations_Switch).to be_off
      end
    end

    context "when the office empties during the day at Christmas with the Christmas lights on" do
      before do
        suspend_rules { Christmas_Lights.members.each { |light| light.update(ON) } }
        Office_Presence_Sensor.update(OFF)
      end

      it "leaves the window decorations on" do
        expect(Office_WindowDecorations_Switch).to be_on
      end
    end
  end

  describe "fan speed" do
    { 0 => 25, 1 => 50, 2 => 75, 3 => 100 }.each do |actual, percent|
      it "shows #{percent}% when the fan reports speed #{actual}" do
        Office_Fan_Speed_Actual.update(actual)

        expect(Office_Fan_Speed.state.to_f).to eq percent
      end
    end

    # The fan has speeds 0 to 3 and the slider is 0 to 100, so each commanded value rounds up to the next 25% step
    { 10 => [0, 25], 25 => [0, 25], 30 => [1, 50], 60 => [2, 75], 100 => [3, 100] }.each do |command, (speed, percent)|
      context "when the slider is moved to #{command}%" do
        before { Office_Fan_Speed.command(command) }

        it "sets the fan to speed #{speed}" do
          expect(Office_Fan_Speed_Actual.state.to_i).to eq speed
        end

        it "moves the slider to #{percent}%" do
          expect(Office_Fan_Speed.state.to_f).to eq percent
        end
      end
    end

    context "when the slider gets a command that is not a number" do
      before do
        Office_Fan_Speed_Actual.update(1)
        Office_Fan_Speed.command(INCREASE)
      end

      it "does not set a fan speed" do
        expect(Office_Fan_Speed_Actual.state.to_i).to eq 1
      end

      it "does not make the rule fail" do
        expect(spec_log_lines).not_to include(a_string_including("Failed to execute rule 'office"))
      end
    end
  end

  describe "UPS battery shutdown" do
    before do
      Office_DiskArrayPlug_Switch.update(ON)
      Office_UPS_Status.update(NutUps::Status::ON_BATTERY)
    end

    it "turns off the disk array 5 minutes after the battery drops to the threshold while on battery power" do
      Office_UPS_BatteryCharge.update(90)

      time_travel_and_execute_timers(5.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_off
    end

    it "leaves the disk array on until the 5 minutes have passed" do
      Office_UPS_BatteryCharge.update(90)

      time_travel_and_execute_timers(4.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_on
    end

    it "does not schedule a shutdown while the battery charge is still above the threshold" do
      Office_UPS_BatteryCharge.update(95)

      time_travel_and_execute_timers(5.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_on
    end

    it "does not schedule a shutdown if the disk array is already off" do
      Office_DiskArrayPlug_Switch.update(OFF)
      Office_UPS_BatteryCharge.update(80)

      time_travel_and_execute_timers(5.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_off
    end

    it "does not schedule a shutdown while the UPS is on line power" do
      Office_UPS_Status.update(NutUps::Status::ON_LINE)
      Office_UPS_BatteryCharge.update(80)

      time_travel_and_execute_timers(5.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_on
    end

    it "does not schedule a shutdown while the UPS status is unknown" do
      Office_UPS_Status.update(NULL)
      Office_UPS_BatteryCharge.update(80)

      time_travel_and_execute_timers(5.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_on
    end

    it "cancels the pending shutdown if power returns before the grace period elapses" do
      Office_UPS_BatteryCharge.update(80)
      Office_UPS_Status.update(NutUps::Status::ON_LINE)

      time_travel_and_execute_timers(5.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_on
    end
  end

  describe "on load" do
    it "sets the outdoor temp icon" do
      rule_named("set icon to outdoor-temp on load").trigger

      expect(Office_Awtrix_OutdoorTemp_Icon.state.to_s).to eq "thermometer-outside"
    end
  end
end
