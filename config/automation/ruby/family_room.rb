# frozen_string_literal: true

require "zigbee"

rule "when family room lights turn on/off, turn on/off LEDs" do
  changed FamilyRoom_Lights_Switch

  run { |event| FamilyRoom_LED_Color.ensure.command(event.state) }
end

# Harmony activity labels, as the hub reports them in FamilyRoom_Harmony_Activity
HARMONY_POWER_OFF = "PowerOff"
HARMONY_ACTIVITIES = {
  FamilyRoom_Harmony_WatchTV_Switch => "Watch TV",
  FamilyRoom_Harmony_WatchPC_Switch => "Watch PC",
  FamilyRoom_Harmony_ListenToMusic_Switch => "Listen to Music"
}.freeze

rule "start or stop a harmony activity from its switch" do
  received_command(*HARMONY_ACTIVITIES.keys)

  run do |event|
    activity = HARMONY_ACTIVITIES.fetch(event.item)

    if event.command.on?
      FamilyRoom_Harmony_Activity.command(activity)
    elsif FamilyRoom_Harmony_Activity.state == activity
      FamilyRoom_Harmony_Activity.command(HARMONY_POWER_OFF)
    end
  end
end

# The switches don't autoupdate, so this is the only thing that sets them, including when the remote changes activity
rule "show the running harmony activity on its switch" do
  changed FamilyRoom_Harmony_Activity

  run do |event|
    HARMONY_ACTIVITIES.each { |switch, activity| switch.update(event.state == activity ? ON : OFF) }
  end
end

channel(Zigbee::SINGLE_TAP, thing: FamilyRoom_Fan_Button_Battery.thing) { FamilyRoom_Lights_Switch.toggle }

channel(Zigbee::DOUBLE_TAP, thing: FamilyRoom_Fan_Button_Battery.thing) { FamilyRoom_CeilingFan_Light_Power.toggle }

channel(Zigbee::HOLD, thing: FamilyRoom_Fan_Button_Battery.thing) { FamilyRoom_CeilingFan_Power.toggle }
