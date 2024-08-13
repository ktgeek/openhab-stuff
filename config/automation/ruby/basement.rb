# frozen_string_literal: true

require "homeseer"
require "zwave"

OCCUPANCY_COUNT_LED_GROUPS = Array.new(7) { |i| items["Basement_Occupancy_Count_#{i + 1}"] }.freeze

received_command Basement_Movie_Mode_Switch, command: ON do
  Basement_Stairs_Switch.ensure.off
  Basement_Room_Lights_Switch.ensure.off
  Basement_Room_Theater_Lights.ensure << 9
  Basement_Room_Bar_Lights.ensure << 2 

  after(10.seconds) { Basement_Movie_Mode_Switch.update(OFF) }
end

# when normal mode is turned on
received_command Basement_Normal_Mode_Switch, command: ON do
  Basement_Stairs_Switch.ensure.on
  Basement_Room_Theater_Lights.ensure << 100
  Basement_Room_Bar_Lights.ensure << 100

  after(10.seconds) { Basement_Normal_Mode_Switch.update(OFF) }
end

rule "When the count of the occupancy sensor changes" do
  updated Basement_Occupancy_Counters.members

  run do |event|
    after(25.milliseconds) { C_Total_Basement_Occupancy.update(Basement_Occupancy_Counters.members.sum(&:state)) }

    sensor = items["#{event.item.name[6..-7]}_Sensor"]
    sensor.update(event.state.positive? ? ON : OFF)
  end
end

# When the count of the occupancy sensor changes
updated Basement_Deadend_Occupancy_Counters.members do
  after(25.milliseconds) do
    C_Basement_Deadend_Occupancy.update(Basement_Deadend_Occupancy_Counters.members.sum(&:state))
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

  run do
    if Hiome_Exercise_Room_Occupancy_Count.state.positive?
      Exercise_Room_Light.ensure.on
      if Exercise_Room_Bike_Trainer_Switch.off? && Exercise_Room_Bike_Trainer_Enabled.on?
        Exercise_Room_Bike_Trainer_Switch.ensure.on
      end
    end
  end
end

rule "when someone leaves the deadend" do
  changed C_Basement_Deadend_Occupancy

  run do |event|
    timers.cancel(event.item)

    if C_Basement_Deadend_Occupancy.state < 1
      after(90.seconds, id: event.item) do
        ensure_states do
          Exercise_Room_Light.off
          Exercise_Room_Bike_Trainer_Switch.off
        end
      end
    end
  end
end

rule "when the exercise room door is closed" do
  changed Hiome_Exercise_Room_Door_Contact, to: CLOSED

  run do
    if C_Basement_Deadend_Occupancy.state < 1
      Basement_Hallway_Lights_Switch.ensure.off
      Exercise_Room_Light.ensure.off
      Exercise_Room_Bike_Trainer_Switch.ensure.off

      Basement_Deadend_Occupancy_Counters.members.each { |i| timers.cancel(i) }
    end

    Basement_Stairs_Switch.ensure.off if Hiome_Basement_Occupancy_Count.state < 1
  end
end

rule "when the exercise room door is open" do
  changed Hiome_Exercise_Room_Door_Contact, to: OPEN

  run { Basement_Stairs_Switch.ensure.on }

  only_if { Hiome_Basement_Occupancy_Count.state < 1 }
end

changed(Exercise_Room_Dimmer_Scene_Number_Top, to: ZWave::PADDLE_TWO_CLICKS) { Basement_Stairs_Switch.ensure.on }

changed Exercise_Room_Dimmer_Scene_Number_Top, to: ZWave::PADDLE_THREE_CLICKS do
  Exercise_Room_Bike_Trainer_Enabled.on
  Exercise_Room_Bike_Trainer_Switch.ensure.on
end

changed(Exercise_Room_Dimmer_Scene_Number_Bottom, to: ZWave::PADDLE_TWO_CLICKS) { Basement_Stairs_Switch.ensure.off }

changed Exercise_Room_Dimmer_Scene_Number_Bottom, to: ZWave::PADDLE_THREE_CLICKS do
  Exercise_Room_Bike_Trainer_Enabled.off
  Exercise_Room_Bike_Trainer_Switch.ensure.off
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
