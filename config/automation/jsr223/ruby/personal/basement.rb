# frozen_string_literal: true

require "homeseer"

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

  run do |event|
    after(25.milliseconds) { C_Total_Basement_Occupancy.update(Basement_Occupancy_Counters.members.sum(&:state)) }

    sensor = items["#{event.item.name[6..-7]}_Sensor"]
    sensor.update(event.state.positive? ? ON : OFF)
  end
end

rule "when someone enters/leaves downstairs" do
  changed C_Total_Basement_Occupancy

  run do |event|
    timers.cancel(event.item)

    if C_Total_Basement_Occupancy.state.positive?
      if C_Total_Basement_Occupancy.previous_state(skip_equal: true) < C_Total_Basement_Occupancy.state
        Basement_Stairs_Switch.ensure.on
        Basement_TV_Toast << "Someone has entered the basement"
      end
    else
      after(120.seconds, id: event.item) { C_All_Lights.members.ensure.off }
    end

    C_Occupancy_LEDs.members.ensure << [C_Total_Basement_Occupancy.state, Homeseer::LedColor::WHITE].min

    # Turn on and off LEDs to do a "meter" of how many people are in the basement
    OCCUPANCY_COUNT_LED_GROUPS[0, C_Total_Basement_Occupancy.state].each do |led_group|
      led_group.members.ensure << Homeseer::LedColor::BLUE
    end
    OCCUPANCY_COUNT_LED_GROUPS[C_Total_Basement_Occupancy.state..]&.each do |led_group|
      led_group.members.ensure << Homeseer::LedColor::OFF
    end
  end
end

rule "when someone enters/leaves the exercise room" do
  changed Hiome_Exercise_Room_Occupancy_Count

  run do |event|
    timers.cancel(event.item)

    if Hiome_Exercise_Room_Occupancy_Count.state.positive?
      Exercise_Room_Light.ensure.on
      if Exercise_Room_Bike_Trainer_Switch.off? && Exercise_Room_Bike_Trainer_Enabled.on?
        Exercise_Room_Bike_Trainer_Switch.ensure.on
      end
    else
      after(90.seconds, id: event.item) do
        Exercise_Room_Light.ensure.off
        Exercise_Room_Bike_Trainer_Switch.ensure.off
      end
    end
  end
end

rule "when the exercise room door is closed" do
  changed Hiome_Exercise_Room_Door_Contact, to: CLOSED

  run do
    Basement_Hallway_Lights_Switch.ensure.off
    Exercise_Room_Light.ensure.off
    Exercise_Room_Bike_Trainer_Switch.ensure.off

    Basement_Deadend_Occupancy_Counters.members.each { |i| timers.cancel(i) }
  end

  only_if { Basement_Deadend_Occupancy_Counters.members.sum(&:state) < 1 }
end

rule "when the exercise room dimmer has a scene change" do
  updated Exercise_Room_Dimmer_Scene_Number

  run do |event|
    case event.state
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
    timers.cancel(event.item)

    if Hiome_Basement_Hallway_Occupancy_Count.state.positive?
      Basement_Hallway_Lights_Switch.ensure.on
    else
      after(60.seconds, id: event.item) { Basement_Hallway_Lights_Switch.ensure.off }
    end
  end
end

rule "because shit is broke and stupid on the basement switch" do
  changed Basement_Christmas_Tree, Basement_Wall_Outlet_Switch

  run do |event|
    Basement_Christmas_Tree.ensure << event.state
    Basement_Wall_Outlet_Switch.ensure << event.state
  end
end
