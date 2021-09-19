# frozen_string_literal: true

require 'openhab'

rule "night lights on" do
  channel "astro:sun:local:set#event", triggered: "START"

  run do
    Front_Yard_Lights.on unless Front_Yard_Lights.on?
    All_Hall_Lights.on unless All_Hall_Lights.on?
  end
end

rule "Nights off at end of day" do
  cron "0 30 22 ? * *"

  run do
    unless VisitorMode_Switch.on?
      Front_Yard_Lights.off unless Front_Yard_Lights.off?
      All_Hall_Lights.off unless All_Hall_Lights.off?
    else
      logger.info("Visitor mode on, not turning off lights")
    end
  end
end

# We are generally still not rocking out at 3am
rule "reset visitor mode" do
  cron "0 0 3 ? * *"

  run do
    VisitorMode_Switch.off unless VisitorMode_Switch.off?
    Front_Yard_Lights.off unless Front_Yard_Lights.off?
    All_Hall_Lights.off unless All_Hall_Lights.off?
  end
end
