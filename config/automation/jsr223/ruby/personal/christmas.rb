require 'openhab'

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
