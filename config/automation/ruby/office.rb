# frozen_string_literal: true

require "color"
require "tasmota"
require "holidays"
require "nut_ups"
# The server starts its own shutdown once the UPS battery drops to this percentage; after that, give it this much
# time (way more than enough) to finish before we turn off the disk array.
UPS_SHUTDOWN_BATTERY_THRESHOLD = 90
UPS_SHUTDOWN_GRACE_PERIOD = 5.minutes

rule "when a zoom meeting is on" do
  changed Zoom_Active_Switch, to: ON

  run do
    Office_DoorLED_Fade.off
    Office_DoorLED_Scheme.command(Tasmota::Scheme::SINGLE_COLOR)
    Office_DoorLED_Color.command(Color::RED)
  end
end

rule "when a zoom meeting is over" do
  changed Zoom_Active_Switch, to: OFF

  run do
    prior_color = Office_DoorLED_Color.last_state
    if prior_color&.on?
      Office_DoorLED_Color.command(prior_color)
      Office_DoorLED_Scheme.ensure.command(Office_DoorLED_Scheme.last_state) if Office_DoorLED_Scheme.last_state
      Office_DoorLED_Fade.ensure.command(Office_DoorLED_Fade.last_state) if Office_DoorLED_Fade.last_state
      Office_DoorLED_Palette.ensure.command(Office_DoorLED_Palette.last_state) if Office_DoorLED_Palette.last_state
      Office_DoorLED_Speed.ensure.command(Office_DoorLED_Speed.last_state) if Office_DoorLED_Speed.last_state
    else
      Office_DoorLED_Color.ensure.off
    end
  end
end

rule "turn on the light if someone enters the office" do
  changed Office_Presence_Sensor, to: ON

  run do
    ensure_states do
      Office_Lights_Switch.on
      # Office_Monitor_LED.on
      Office_WindowDecorations_Switch.on if Holiday_Mode.state == Holidays::CHRISTMAS && Sun_Status.state == "UP"
    end
  end
end

rule "turn off the light when the office is empty" do
  changed Office_Presence_Sensor, to: OFF

  run do
    ensure_states do
      Office_Lights_Switch.off
      # Office_Monitor_LED.off
      if Holiday_Mode.state == Holidays::CHRISTMAS && Sun_Status.state == "UP" && Christmas_Lights.off?
        Office_WindowDecorations_Switch.off
      end
    end
  end
end

def fan_speed_to_percentage(speed)
  (speed.to_i * 25) + 25
end

# Fan does 0-3, where 0 is a speed that is not off, but 25%
changed(Office_Fan_Speed_Actual) { |event| Office_Fan_Speed.ensure.update(fan_speed_to_percentage(event.item.state)) }

received_command Office_Fan_Speed do |event|
  speed = [((event.item.state.to_f / 25) - 1).ceil.to_i, 0].max
  Office_Fan_Speed_Actual.ensure.command(speed)
  # Ensure we bounce the UI to the highest 25% increment, so that the slider is always at a valid value.
  Office_Fan_Speed.ensure.update(fan_speed_to_percentage(speed))
end

updated(Office_UPS_BatteryCharge) do |event|
  # Office_UPS_Status is NULL after a restart until NUT reports
  on_battery = Office_UPS_Status.state&.split&.include?(NutUps::Status::ON_BATTERY)

  if on_battery && Office_DiskArrayPlug_Switch.on? && event.item.state.to_i <= UPS_SHUTDOWN_BATTERY_THRESHOLD
    after(UPS_SHUTDOWN_GRACE_PERIOD, id: Office_UPS) { Office_DiskArrayPlug_Switch.ensure.off }
  end
end

updated(Office_UPS_Status) do |event|
  on_line = event.item.state&.split&.include?(NutUps::Status::ON_LINE)

  timers.cancel(Office_UPS) if on_line && timers.include?(Office_UPS)
end
