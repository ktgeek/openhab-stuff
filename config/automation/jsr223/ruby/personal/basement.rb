# frozen_string_literal: true

require 'openhab'
require 'homeseer'

off_timers ||= {}
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
  updated Basement_Occupancy_Counters.members

  triggered do |item|
    after(25.milliseconds) { C_Total_Basement_Occupancy.update(Basement_Occupancy_Counters.members.sum) }

    sensor = items["#{item.name[6..-7]}_Sensor"]
    sensor.update(item.positive? ? ON : OFF)
  end
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
    else
      off_timers[event.item] = after(120.seconds) { C_All_Lights.each { |i| i.ensure.off } }
    end

    color = [C_Total_Basement_Occupancy, Homeseer::LedColor::WHITE].min
    C_Occupancy_LEDs.each { |i| i.ensure << color }

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
    else
      off_timers[event.item] = after(90.seconds) do
        Exercise_Room_Light.ensure.off
        Exercise_Room_Bike_Trainer_Switch.ensure.off
      end
    end
  end
end

rule "when the exersize room door is closed" do
  changed Hiome_Exercise_Room_Door_Contact, to: CLOSED

  run do
    off_timers.delete(Hiome_Exercise_Room_Occupancy_Count)&.cancel
    Basement_Hallway_Lights_Switch.ensure.off
    Exercise_Room_Light.ensure.off
    Exercise_Room_Bike_Trainer_Switch.ensure.off
  end

  only_if { Hiome_Exercise_Room_Occupancy_Count + Hiome_Basement_Hallway_Occupancy_Count < 1 }
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

rule "when someone enters the basement hallway" do
  changed Hiome_Basement_Hallway_Occupancy_Count

  run do |event|
    off_timers.delete(event.item)&.cancel

    if Hiome_Basement_Hallway_Occupancy_Count.positive?
      Basement_Hallway_Lights_Switch.ensure.on
    else
      off_timers[event.item] = after(60.seconds) { Basement_Hallway_Lights_Switch.ensure.off }
    end
  end
end
