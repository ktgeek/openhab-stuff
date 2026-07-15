# frozen_string_literal: true

RSpec.describe "office.rb" do
  describe "Zoom LED" do
    it "sets the door LED to solid red when a Zoom meeting starts" do
      Office_DoorLED_Fade.update(ON)
      Zoom_Active_Switch.update(ON)

      expect(Office_DoorLED_Fade).to be_off
      expect(Office_DoorLED_Scheme.state).to eq Tasmota::Scheme::SINGLE_COLOR
      expect(Office_DoorLED_Color.state).to eq Color::RED
    end

    it "restores the prior color when the meeting ends if one was set" do
      Office_DoorLED_Color.update(Color::WARM_WHITE)
      Zoom_Active_Switch.update(ON)
      Zoom_Active_Switch.update(OFF)

      expect(Office_DoorLED_Color.state).to eq Color::WARM_WHITE
    end

    it "turns the door LED off when the meeting ends and there was no prior color" do
      Zoom_Active_Switch.update(ON)
      Zoom_Active_Switch.update(OFF)

      expect(Office_DoorLED_Color).to be_off
    end
  end

  describe "office presence" do
    it "turns on the office lights when someone enters" do
      Office_Lights_Switch.update(OFF)
      Office_Presence_Sensor.update(ON)

      expect(Office_Lights_Switch).to be_on
    end

    it "turns off the office lights when the office is empty" do
      Office_Lights_Switch.update(ON)
      Office_Presence_Sensor.update(OFF)

      expect(Office_Lights_Switch).to be_off
    end
  end

  describe "UPS battery shutdown" do
    before do
      Office_DiskArrayPlug_Switch.update(ON)
      Office_UPS_Status.update(NutUps::Status::ON_BATTERY)
    end

    it "turns off the disk array 5 minutes after the battery drops to the threshold while on battery power" do
      Office_UPS_BatteryCharge.update(90)

      expect(Office_DiskArrayPlug_Switch).to be_on
      time_travel_and_execute_timers(5.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_off
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

    it "cancels the pending shutdown if power returns before the grace period elapses" do
      Office_UPS_BatteryCharge.update(80)
      Office_UPS_Status.update(NutUps::Status::ON_LINE)

      time_travel_and_execute_timers(5.minutes)
      expect(Office_DiskArrayPlug_Switch).to be_on
    end

    it "does not raise when the UPS status is NULL" do
      Office_UPS_Status.update(NULL)

      expect { Office_UPS_BatteryCharge.update(80) }.not_to raise_error
    end
  end
end
