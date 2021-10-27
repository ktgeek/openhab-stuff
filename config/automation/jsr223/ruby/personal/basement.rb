# frozen_string_literal: true

require 'openhab'
require 'homeseer'

off_timers = {}
OCCUPANCY_COUNT_LED_GROUPS = Array.new(7) { |i| items["Basement_Occupancy_Count_#{i + 1}"] }.freeze

rule "when movie mode is turned on" do
  received_command Basement_Movie_Mode_Switch, command: ON

  run do
    Basement_Stairs_Switch.ensure.off
    Basement_Room_Lights_Switch.ensure.off
    Basement_Room_Theater_Lights.ensure << 9
    Basement_Room_Bar_Lights.ensure << 10

    after(10.seconds) { Basement_Movie_Mode_Switch.update(OFF) }
  end
end

rule "when normal mode is turned on" do
  received_command Basement_Normal_Mode_Switch, command: ON

  run do
    Basement_Stairs_Switch.ensure.on
    Basement_Room_Theater_Lights.ensure << 100
    Basement_Room_Bar_Lights.ensure << 100

    after(10.seconds) { Basement_Normal_Mode_Switch.update(OFF) }
  end
end

rule "When the count of the occupancy sensor changes" do
  updated [Hiome_Basement_Occupancy_Count, Hiome_Exercise_Room_Occupancy_Count]

  run do
    after(25.milliseconds) do
      new_total_occupancy = Hiome_Basement_Occupancy_Count + Hiome_Exercise_Room_Occupancy_Count
      C_Total_Basement_Occupancy.update(new_total_occupancy)
    end
  end
end

rule "When someone enters/leaves the main basement area" do
  updated Hiome_Basement_Occupancy_Count
  run { Basement_Occupancy_Sensor.update(Hiome_Basement_Occupancy_Count.positive? ? ON : OFF) }
end

rule "when someone enters/leaves downstairs" do
  changed C_Total_Basement_Occupancy

  run do |event|
    off_timers.delete(event.item)&.cancel

    if C_Total_Basement_Occupancy.positive?
      if C_Total_Basement_Occupancy.previous_state(skip_equal: true) < C_Total_Basement_Occupancy
        Basement_Stairs_Switch.ensure.on
        Basement_TV_Toast << "Someone has entered the basement"
      end

      C_Occupancy_LEDs.each { |i| i.ensure << Homeseer::LedColor::CYAN }
    else
      off_timers[event.item] = after(120.seconds) { C_All_Lights.each { |i| i.ensure.off } }
      C_Occupancy_LEDs.each { |i| i.ensure << Homeseer::LedColor::OFF }
    end

    # Turn on and off leds to do a "meter" of how many people are in the basement
    OCCUPANCY_COUNT_LED_GROUPS[0, C_Total_Basement_Occupancy].each do |led_group|
      led_group.each { |led| led << Homeseer::LedColor::BLUE unless led.state && led.state == Homeseer::LedColor::BLUE }
    end
    OCCUPANCY_COUNT_LED_GROUPS[C_Total_Basement_Occupancy..-1]&.each do |led_group|
      led_group.each { |led| led << Homeseer::LedColor::OFF unless led.state.nil? || led.state == Homeseer::LedColor::OFF }
    end
  end
end

rule "when someone enters/leaves the exercise room" do
  changed Hiome_Exercise_Room_Occupancy_Count

  run do |event|
    off_timers.delete(event.item)&.cancel

    if Hiome_Exercise_Room_Occupancy_Count.positive?
      Exercise_Room_Light.ensure.on
      if Exercise_Room_Bike_Trainer_Switch.off? && Exercise_Room_Bike_Trainer_Enabled.on?
        Exercise_Room_Bike_Trainer_Switch.ensure.on
      end
      Exercise_Room_Occupancy_Sensor.update(ON)
    else
      off_timers[event.item] = after(90.seconds) do
        Exercise_Room_Light.ensure.off
        Exercise_Room_Bike_Trainer_Switch.ensure.off
      end
      Exercise_Room_Occupancy_Sensor.update(OFF)
    end
  end
end

rule "when the exersize room dimmer has a scene change" do
  updated Exercise_Room_Dimmer_Scene_Number

  run do
    case Exercise_Room_Dimmer_Scene_Number
    when Homeseer::PADDLE_UP_TWO_CLICKS
      Basement_Stairs_Switch.ensure.on
    when Homeseer::PADDLE_DOWN_TWO_CLICKS
      Basement_Stairs_Switch.ensure.off
    when Homeseer::PADDLE_UP_THREE_CLICKS
      Exercise_Room_Bike_Trainer_Enabled.on
      Exercise_Room_Bike_Trainer_Switch.ensure.on
    when Homeseer::PADDLE_DOWN_THREE_CLICKS
      Exercise_Room_Bike_Trainer_Enabled.off
      Exercise_Room_Bike_Trainer_Switch.ensure.off
    end
  end
end
