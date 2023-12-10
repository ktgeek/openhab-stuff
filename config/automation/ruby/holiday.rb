# frozen_string_literal: true

require "tasmota"

rule "decorations on at sunset at Halloween" do
  channel "astro:sun:local:set#event", triggered: "START"

  run do
    ensure_states do
      Porch_Decorations_Switch.on
      Front_Yard_Outdoor_Decorations_Switch.on

    if Zoom_Active_Switch.off?
        Office_Door_LED_Power.on
        Office_Door_LED_Fade.on
        Office_Door_LED_Palette << Tasmota::Palette::PURPLE_FADE
        Office_Door_LED_Scheme << Tasmota::Scheme::CYCLE_UP
      end
    end

    # Leaving on this while testing to ensure this didn't trigger
    # Kitchen_Echo_TTS << "Spooky! Scary! Halloween!"
    # Basement_Echo_TTS << "Spooky! Scary! Halloween!"
  end

  only_if { Holiday_Mode.state == "Halloween" }
end

rule "decorations on at sunset at Christmas" do
  channel "astro:sun:local:set#event", triggered: "START"

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
      Front_Yard_Outdoor_Decorations_Switch.off
      Office_Door_LED_Power.off
    end
  end

  only_if { VisitorMode_Switch.off? && Holiday_Mode.state == "Halloween" }
end

rule "decorations off at night at Christmas" do
  cron "0 30 22 ? * *"

  run do
    Christmas_Outside.members.off
    Christmas_Lights_All.members.off
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
        Front_Yard_Outdoor_Decorations_Switch.off
        Office_Door_LED_Power.off
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
      Christmas_Outside.members.off
      Christmas_Lights_All.members.off
    end
  end

  only_if { Holiday_Mode.state == "Christmas" }
end

rule "christ switch is turned on" do
  changed Christmas_Lights, from: OFF, to: ON

  run do
    if Zoom_Active_Switch.off?
      ensure_states do
        Office_Door_LED_Fade.on
        Office_Door_LED_Palette << Tasmota::Palette::RED_GREEN_CROSSFADE
        Office_Door_LED_Scheme << Tasmota::Scheme::CYCLE_UP
      end
    end
  end

  only_if { Holiday_Mode.state == "Christmas" }
end

# rule "red button is pressed" do
#   updated Red_Button_Action, to: "single"

#   run do
#     Front_Yard_Wolf_Decoration.toggle
#   end
# end

# every 15 minutes set a timer to set off jeff sometime in the next 15 mintues
# rule "randomly shoot off jeff" do
#   cron "0 */15 15-19 ? * *"

#   run do
#     time = Random.rand(900)
#     logger.warn("Setting off Jeff in #{time} seconds")
#     after(time.seconds) { Front_Yard_Wolf_Decoration.toggle }
#   end
# end
