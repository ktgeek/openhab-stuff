# frozen_string_literal: true

changed(Kitchen_Bathroom_Contact_Sensor, to: "OPEN") do
  timers.cancel(Kitchen_Bathroom_Light_Switch)
  timers.cancel(Kitchen_Bathroom_Fan_Switch)

  after(2.minutes, id: Kitchen_Bathroom_Light_Switch) { Kitchen_Bathroom_Light_Switch.ensure.off }
  after(5.minutes, id: Kitchen_Bathroom_Fan_Switch) { Kitchen_Bathroom_Fan_Switch.ensure.off }
end

changed(Kitchen_Bathroom_Contact_Sensor, to: "CLOSED") do
  timers.cancel(Kitchen_Bathroom_Light_Switch)
  timers.cancel(Kitchen_Bathroom_Fan_Switch)
end
