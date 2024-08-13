# frozen_string_literal: true

require "color"
require "tasmota"

stored_led_states = nil

rule "when a zoom meeting is on" do
  changed Zoom_Active_Switch, to: ON

  run do
    if Office_Door_LED_Power.on?
      stored_led_states = store_states Office_Door_LED_Palette, Office_Door_LED_Fade, Office_Door_LED_Scheme,
                                       Office_Door_LED_Speed
    end

    ensure_states do
      Office_Door_LED_Power.on
      Office_Door_LED_Fade.off
      Office_Door_LED_Scheme.command(Tasmota::Scheme::SINGLE_COLOR)
      Office_Door_LED_Color.command(Color::RED)
    end
  end
end

rule "when a zoom meeting is over" do
  changed Zoom_Active_Switch, to: OFF

  run do
    if stored_led_states
      stored_led_states&.restore_changes
      stored_led_states = nil
    else
      Office_Door_LED_Power.ensure.off
    end
  end
end

rule "turn on the light if someone enters the office" do
  changed Office_Presence_Event, to: "enter"

  run do |event|
    ensure_states do
      Office_Lights_Switch.on
      Office_Monitor_LED.on
    end

    # Sometimes if you walk in and out of the room too quickly, the light will not turn off as the presence sensor won't
    # turn on. If it never turns on, it can never change to off so it won't trigger the turn off. 2 minutes is enough
    # time for that to flip, so this will be a no op, but just in case, let's capture those edge cases where are too
    # fast.
    #
    # There was recently a firmware update that greatly improved the speed to presence detection, to where the event and
    # the presence are in a race condition.  This may not be needed anymore, but I'm leaving it in for now until more
    # real world testing can be done.
    timers.cancel(event.item)
    after(120.seconds, id: event.item) do
      if Office_Presence_Sensor.off?
        ensure_states do
          Office_Lights_Switch.off
          Office_Monitor_LED.off
        end
      end
    end
  end

  # only_if { Office_Presence_Sensor.off? }
end

rule "turn off the light when the office is empty" do
  changed Office_Presence_Sensor, to: OFF

  run do
    ensure_states do
      Office_Lights_Switch.off
      Office_Monitor_LED.off
    end
  end
end

# Fan does 0-3, where 0 is a speed that is not off, but the slider does 0-4, so we need to add 1 to the value.
changed Office_Fan_Speed_Actual do |event|
  Office_Fan_Speed.ensure.update(event.state.to_i + 1)
end

received_command Office_Fan_Speed do |event|
  speed = [event.item.state.to_i - 1, 0].max
  Office_Fan_Speed_Actual.ensure.command(speed)
end
