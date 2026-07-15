# frozen_string_literal: true

require "night_off"

night_off_rule("Nights off at end of day") do
  Front_Yard_Lights.members.ensure.off
  All_Hall_Lights.members.ensure.off
end

# We are generally still not rocking out at 3am
rule "reset visitor mode" do
  cron "0 0 3 ? * *"

  run { VisitorMode_Switch.ensure.off }
end
