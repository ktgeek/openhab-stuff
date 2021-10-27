# frozen_string_literal: true

require 'openhab'
require 'wifi_led'

rule "decorations on at sunset" do
  channel "astro:sun:local:set#event", triggered: "START"

  run do
    Porch_Decoriations_Switch.ensure.on
    Front_Yard_Outdoor_Decorations_Switch.ensure.on
    # Setting the program also turns on the light if its off.
    # We only want to do this if the office isn't already on, making an assumption i'm already in a meeting...
    if Zoom_Active_Switch.off? && Office_Door_LED_Program != WifiLED::Program::PURPLE_FADE
      Office_Door_LED_Program << WifiLED::Program::PURPLE_FADE
    end
  end
end

rule "decoriations off at night" do
  cron "0 30 22 ? * *"

  run do
    unless VisitorMode_Switch.on?
      Porch_Decoriations_Switch.ensure.off
      Front_Yard_Outdoor_Decorations_Switch.ensure.off
      Office_Door_LED_Power.ensure.off
    end
  end
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
end

# This rules aren't translated into ruby yet, but I didn't want to lose what they were

# var Timer Office_Door_LED_Timer = null

# rule "Christmas Lights On at sunset"
# when
#   Channel "astro:sun:shifted:set#event" triggered START
# then
#   if (Christmas_Outside.state != ON) {
#     Christmas_Outside.sendCommand(ON)
#   }

#   if (Christmas_Lights.state != ON) {
#     Christmas_Lights.sendCommand(ON)
#   }
# end

# rule "Christmas Nights off at end of day"
# when
#  Time cron "0 30 22 ? * *"
# then
#   if (VisitorMode_Switch.state != ON) {
#     if (Christmas_Outside.state != OFF) {
#       Christmas_Outside.sendCommand(OFF)
#     }

# 	// Just send blanket send it off just in case
#     Christmas_Lights_All.sendCommand(OFF)
#   }
# end

# rule "Christmas Switch is turned on"
# when
#   Item Christmas_Lights changed from OFF to ON
# then
#   if (Office_Door_LED_Timer !== null) {
#     Office_Door_LED_Timer.cancel()
#     Office_Door_LED_Timer = null
#   }
#   // It seems to get really angry if I send too many wifi commands at the same time,
#   // so let's delay the mode switch by 2 seconds
#   Office_Door_LED_Timer = createTimer(now.plusSeconds(2), [|
#     Office_Door_LED_Program.sendCommand(45)
#   ])

#   Kitchen_Echo_TTS.sendCommand("Merry Christmas!")
#   Basement_Echo_TTS.sendCommand("Merry Christmas!")
# end
