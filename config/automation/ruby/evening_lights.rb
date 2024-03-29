# frozen_string_literal: true

rule "Nights off at end of day" do
  cron "0 30 22 ? * *"

  run do
    if VisitorMode_Switch.on?
      logger.info("Visitor mode on, not turning off lights")
    else
      Front_Yard_Lights.members.ensure.off
      All_Hall_Lights.members.ensure.off
    end
  end
end

rule "when we turn off VisitorMode" do
  changed VisitorMode_Switch, to: OFF

  run do
    case Time.now
    when between("10:30pm".."3am")
      VisitorMode_Switch.ensure.off
      Front_Yard_Lights.members.ensure.off
      All_Hall_Lights.members.ensure.off
    end
  end
end

# We are generally still not rocking out at 3am
rule "reset visitor mode" do
  cron "0 0 3 ? * *"

  run { VisitorMode_Switch.ensure.off }
end
