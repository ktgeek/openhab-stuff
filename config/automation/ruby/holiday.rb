# frozen_string_literal: true

require "color"
require "tasmota"

rule "its light out, turn off the holiday decorations" do
  changed Sun_Status, to: "UP"

  run do
    ensure_states do
      Porch_Decorations_Switch.off
      Front_Yard_Side_Holiday_Decorations_Switch.off
      Office_Door_LED_Power.off
    end
  end

  only_if { Holiday_Mode.state.present? }
end

rule "decorations on at sunset at Halloween" do
  changed Sun_Status, to: "DOWN"

  run do
    ensure_states do
      Porch_Decorations_Switch.on
      Front_Yard_Side_Holiday_Decorations_Switch.on
      HiddenRoom_Holiday_LED_Power.on
      DinahsRoom_Holiday_LED_Power.on
    end

    if Zoom_Active_Switch.off?
      Office_Door_LED_Power.on
      Office_Door_LED_Fade.on
      Office_Door_LED_Color.command(Color::PURPLE)
      Office_Door_LED_Palette.command(Tasmota::Palette::PURPLE_FADE)
      Office_Door_LED_Scheme.command(Tasmota::Scheme::CYCLE_UP)
    end

    # Leaving on this while testing to ensure this didn't trigger
    # Kitchen_Echo_TTS.command("Spooky! Scary! Halloween!")
    # Basement_Echo_TTS.command("Spooky! Scary! Halloween!")
  end

  only_if { Holiday_Mode.state == "Halloween" }
end

rule "decorations on at sunset at Christmas" do
  changed Sun_Status, to: "DOWN"

  run do
    Christmas_Outside.members.ensure.on
    Christmas_Lights.members.ensure.on
  end

  only_if { Holiday_Mode.state == "Christmas" }
end

rule "decorations off at night at Halloween" do
  cron "0 30 22 ? * *"

  run do
    ensure_states do
      Porch_Decorations_Switch.off
      Front_Yard_Side_Holiday_Decorations_Switch.off
      Office_Door_LED_Power.off
      HiddenRoom_Holiday_LED_Power.off
      DinahsRoom_Holiday_LED_Power.off
    end
  end

  only_if { VisitorMode_Switch.off? && Holiday_Mode.state == "Halloween" }
end

rule "decorations off at night at Christmas" do
  cron "0 30 22 ? * *"

  run do
    Christmas_Outside.members.ensure.off
    Christmas_Lights_All.members.ensure.off
  end

  only_if { VisitorMode_Switch.off? && Holiday_Mode.state == "Christmas" }
end

rule "when we turn off VisitorMode" do
  changed VisitorMode_Switch, to: OFF

  run do
    case Time.now
    when between("22:30".."23:59:59"), between("0:00".."3:01")
      ensure_states do
        Porch_Decorations_Switch.off
        Front_Yard_Side_Holiday_Decorations_Switch.off
        Office_Door_LED_Power.off
        HiddenRoom_Holiday_LED_Power.off
        DinahsRoom_Holiday_LED_Power.off
      end
    end
  end

  only_if { Holiday_Mode.state == "Halloween" }
end

rule "when we turn off VisitorMode" do
  changed VisitorMode_Switch, to: OFF

  run do
    case Time.now
    when between("22:30".."23:59:59"), between("0:00".."3:01")
      Christmas_Outside.members.ensure.off
      Christmas_Lights_All.members.ensure.off
    end
  end

  only_if { Holiday_Mode.state == "Christmas" }
end

rule "christmas switch is turned on" do
  changed Christmas_Lights, from: OFF, to: ON

  run do
    if Zoom_Active_Switch.off?
      ensure_states do
        Office_Door_LED_Fade.on
        Office_Door_LED_Palette.command(Tasmota::Palette::RED_GREEN_CROSSFADE)
        Office_Door_LED_Scheme.command(Tasmota::Scheme::CYCLE_UP)
      end
    end
  end

  only_if { Holiday_Mode.state == "Christmas" }
end

# wolf_last_change = nil

# updated(Front_Yard_Decoration_Mat_Contact, to: CLOSED) do
#   now = Time.now
#   logger.warn("Wolf mat triggered: #{wolf_last_change} now: #{now}")
#   if wolf_last_change.nil? || wolf_last_change < 15.seconds.ago
#     Front_Yard_Wolf_Decoration.toggle
#     wolf_last_change = now
#     Notification.send("Jeff triggered by mat!")
#   end
# end

# received_command(Red_Button_Action, command: Zigbee::Events::SINGLE_TAP) { Misc_Decoration_Switch.toggle }
# received_command(Red_Button_Action, command: Zigbee::Events::SINGLE_TAP) { Front_Yard_Wolf_Decoration.toggle }

# every 15 minutes set a timer to set off jeff sometime in the next 15 mintues
# rule "randomly shoot off jeff" do
#   cron "0 */15 15-19 ? * *"

#   run do
#     time = Random.rand(900)
#     logger.warn("Setting off Jeff in #{time} seconds")
#     after(time.seconds) { Front_Yard_Wolf_Decoration.toggle }
#   end
# end

# rule "christmas: proxy changes to actual back to target" do
#   updated Christmas_Lights, Christmas_Lights_All, Christmas_Outside

#   run do |event|
#     items["#{event.item.name}_HK"].ensure.update(event.state) if Holiday_Mode.state == "Christmas"
#   end
# end

# rule "christmas: proxy on/off command" do
#   received_command Christmas_Lights_HK, Christmas_Lights_All_HK, Christmas_Outside_HK

#   run do |event|
#     item_actual = items[event.item.name[0..-4]]
#     item_actual.ensure.command(event.command)
#   end
# end
