# frozen_string_literal: true

require "homeseer"
require "zwave"
require "tv_notification"

# OCCUPANCY_COUNT_LED_GROUPS = Array.new(7) { |i| items["Basement_Occupancy_Count_#{i.succ}"] }.freeze

received_command C_Basement_Movie_Switch, command: ON do
  Basement_Stairs_Switch.ensure.off
  Basement_Room_Lights_Switch.ensure.off
  Basement_TheaterLights.ensure.command(9)
  Basement_BarLights.ensure.command(2)

  after(10.seconds) { C_Basement_Movie_Switch.update(OFF) }
end

# when normal mode is turned on
received_command C_Basement_Normal_Switch, command: ON do
  Basement_Stairs_Switch.ensure.on
  Basement_TheaterLights.ensure.command(100)
  Basement_BarLights.ensure.command(100)

  after(10.seconds) { C_Basement_Normal_Switch.update(OFF) }
end

rule "When the count of the occupancy sensor changes" do
  updated Basement_Occupancy_Counters.members

  run do |event|
    after(25.milliseconds) { C_Total_Basement_Occupancy.update(Basement_Occupancy_Counters.members.sum(&:state)) }

    sensor = items["#{event.item.name.partition('_').first}_Occupancy_Sensor"]
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
        TvNotification.notify(
          message: "Someone has entered the basement",
          only: Basement_TV_Toast,
          avoid_appletv: false
        )
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
  changed ExerciseRoom_Hiome_Occupancy_Count

  run do
    ensure_states do
      if ExerciseRoom_Hiome_Occupancy_Count.state.positive?
        ExerciseRoom_Light.on
        ExerciseRoom_BikeTrainer_Switch.on if ExerciseRoom_BikeTrainer_Enabled.on?
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
          ExerciseRoom_Light.off
          ExerciseRoom_BikeTrainer_Switch.off
        end
      end
    end
  end
end

rule "when the exercise room door is closed" do
  changed ExerciseRoom_Hiome_Door_Contact, to: CLOSED

  run do
    ensure_states do
      if C_Basement_Deadend_Occupancy.state < 1
        Basement_Hallway_Lights_Switch.off
        ExerciseRoom_Light.off
        ExerciseRoom_BikeTrainer_Switch.off

        Basement_Deadend_Occupancy_Counters.members.each { |i| timers.cancel(i) }
      end

      Basement_Stairs_Switch.off if Basement_Hiome_Occupancy_Count.state < 1
    end
  end
end

rule "when the exercise room door is open" do
  changed ExerciseRoom_Hiome_Door_Contact, to: OPEN

  run { Basement_Stairs_Switch.ensure.on }

  only_if { Basement_Hiome_Occupancy_Count.state < 1 }
end

updated(ExerciseRoom_DimmerLights_Scene_1, to: ZWave::Paddle::TWO_CLICKS) { Basement_Stairs_Switch.ensure.on }

updated(ExerciseRoom_DimmerLights_Scene_1, to: ZWave::Paddle::THREE_CLICKS) do
  ExerciseRoom_BikeTrainer_Enabled.on
  ExerciseRoom_BikeTrainer_Switch.ensure.on
end

updated(ExerciseRoom_DimmerLights_Scene_2, to: ZWave::Paddle::TWO_CLICKS) { Basement_Stairs_Switch.ensure.off }

updated(ExerciseRoom_DimmerLights_Scene_2, to: ZWave::Paddle::THREE_CLICKS) do
  ExerciseRoom_BikeTrainer_Enabled.off
  ExerciseRoom_BikeTrainer_Switch.ensure.off
end

rule "when someone enters the basement hallway" do
  changed BasementHallway_Hiome_Occupancy_Count

  run do |event|
    timers.cancel(event.item)

    if BasementHallway_Hiome_Occupancy_Count.state.positive?
      Basement_Hallway_Lights_Switch.ensure.on
    else
      after(60.seconds, id: event.item) { Basement_Hallway_Lights_Switch.ensure.off }
    end
  end
end
