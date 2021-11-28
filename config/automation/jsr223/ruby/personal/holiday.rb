# frozen_string_literal: true

require 'openhab'
require 'wifi_led'

rule "decorations on at sunset at Halloween" do
  channel "astro:sun:local:set#event", triggered: "START"

  run do
    Porch_Decoriations_Switch.ensure.on
    Front_Yard_Outdoor_Decorations_Switch.ensure.on

    # Setting the program also turns on the light if its off.
    # We only want to do this if the office isn't already on, making an assumption i'm already in a meeting...
    if Zoom_Active_Switch.off? && Office_Door_LED_Program != program
      Office_Door_LED_Program << WifiLED::Program::PURPLE_FADE
    end

    # Leaving on this while testing to ensure this didn't trigger
    Kitchen_Echo_TTS << "Spooky! Scary! Halloween!"
    Basement_Echo_TTS << "Spooky! Scary! Halloween!"
  end

  only_if { Holiday_Mode == "Halloween" }
end

rule "decorations on at sunset at Christmas" do
  channel "astro:sun:local:set#event", triggered: "START"

  run do
    Christmas_Outside.members.ensure.on
    Christmas_Lights.members.ensure.on
  end

  only_if { Holiday_Mode == "Christmas" }
end

rule "decoriations off at night at Halloween" do
  cron "0 30 22 ? * *"

  run do
    Porch_Decoriations_Switch.ensure.off
    Front_Yard_Outdoor_Decorations_Switch.ensure.off
    Office_Door_LED_Power.ensure.off
  end

  only_if { VisitorMode_Switch.off? && Holiday_Mode == "Halloween" }
end

rule "decoriations off at night at Christmas" do
  cron "0 30 22 ? * *"

  run do
    Christmas_Outside.members.ensure.off
    Christmas_Lights.members.ensure.off
  end

  only_if { VisitorMode_Switch.off? && Holiday_Mode == "Christmas" }
end

rule "when we turn off VisitorMode" do
  changed VisitorMode_Switch, to: OFF

  run do
    case TimeOfDay.now
    when between('22:30'..'11:59:59'), between('0:00'..'3:01')
      Porch_Decoriations_Switch.ensure.off
      Front_Yard_Outdoor_Decorations_Switch.ensure.off
      Office_Door_LED_Power.ensure.off
    end
  end

  only_if { Holiday_Mode == "Halloween" }
end

rule "when we turn off VisitorMode" do
  changed VisitorMode_Switch, to: OFF

  run do
    case TimeOfDay.now
    when between('22:30'..'11:59:59'), between('0:00'..'3:01')
      Christmas_Outside.members.ensure.off
      Christmas_Lights.members.ensure.off
    end
  end

  only_if { Holiday_Mode == "Christmas" }
end

rule "christ switch is turned on" do
  changed Christmas_Lights, from: OFF, to: ON

  run do
    if Zoom_Active_Switch.off? && Office_Door_LED_Program != program
      after(2.seconds) { Office_Door_LED_Program << WifiLED::Program::RED_GREEN_CROSSFADE }
    end
  end

  only_if { Holiday_Mode == "Christmas" }
end
