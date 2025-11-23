# frozen_string_literal: true

require "homeseer"
require "zwave"

# OCCUPANCY_COUNT_LED_GROUPS = Array.new(7) { |i| items["Basement_Occupancy_Count_#{i.succ}"] }.freeze

received_command Basement_Movie_Mode_Switch, command: ON do
  Basement_Stairs_Switch.ensure.off
  Basement_Room_Lights_Switch.ensure.off
  Basement_Room_Theater_Lights.ensure.command(9)
  Basement_Room_Bar_Lights.ensure.command(2)

  after(10.seconds) { Basement_Movie_Mode_Switch.update(OFF) }
end

# when normal mode is turned on
received_command Basement_Normal_Mode_Switch, command: ON do
  Basement_Stairs_Switch.ensure.on
  Basement_Room_Theater_Lights.ensure.command(100)
  Basement_Room_Bar_Lights.ensure.command(100)

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
        Basement_TV_Toast.command("Someone has entered the basement")
      end
    else
      after(120.seconds, id: event.item) { C_All_Lights.members.ensure.off }
    end

    ensure_states do
      C_Occupancy_LEDs.members.command([C_Total_Basement_Occupancy.state, Homeseer::LedColor::WHITE].min)

      # Turn on and off LEDs to do a "meter" of how many people are in the basement
      # commenting out for now. It was fun to figure out but not super useful and just causes a zwave event storm.
      # OCCUPANCY_COUNT_LED_GROUPS[0, C_Total_Basement_Occupancy.state].each do |led_group|
      #   led_group.members.command(Homeseer::LedColor::BLUE)
      # end
      # OCCUPANCY_COUNT_LED_GROUPS[C_Total_Basement_Occupancy.state..]&.each do |led_group|
      #   led_group.members.command(Homeseer::LedColor::OFF)
      # end
    end
  end
end

rule "when someone enters/leaves the exercise room" do
  changed Hiome_Exercise_Room_Occupancy_Count

  run do
    ensure_states do
      if Hiome_Exercise_Room_Occupancy_Count.state.positive?
        Exercise_Room_Light.on
        Exercise_Room_Bike_Trainer_Switch.on if Exercise_Room_Bike_Trainer_Enabled.on?
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
    ensure_states do
      if C_Basement_Deadend_Occupancy.state < 1
        Basement_Hallway_Lights_Switch.off
        Exercise_Room_Light.off
        Exercise_Room_Bike_Trainer_Switch.off

        Basement_Deadend_Occupancy_Counters.members.each { |i| timers.cancel(i) }
      end

      Basement_Stairs_Switch.off if Hiome_Basement_Occupancy_Count.state < 1
    end
  end
end

rule "when the exercise room door is open" do
  changed Hiome_Exercise_Room_Door_Contact, to: OPEN

  run { Basement_Stairs_Switch.ensure.on }

  only_if { Hiome_Basement_Occupancy_Count.state < 1 }
end

channel("scene_1", thing: Exercise_Room_Dimmer.thing, triggered: ZWave::Paddle::TWO_CLICKS) do
  Basement_Stairs_Switch.ensure.on
end

channel("scene_1", thing: Exercise_Room_Dimmer.thing, triggered: ZWave::Paddle::THREE_CLICKS) do
  Exercise_Room_Bike_Trainer_Enabled.on
  Exercise_Room_Bike_Trainer_Switch.ensure.on
end

channel("scene_2", thing: Exercise_Room_Dimmer.thing, triggered: ZWave::Paddle::TWO_CLICKS) do
  Basement_Stairs_Switch.ensure.off
end

channel("scene_2", thing: Exercise_Room_Dimmer.thing, triggered: ZWave::Paddle::THREE_CLICKS) do
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
