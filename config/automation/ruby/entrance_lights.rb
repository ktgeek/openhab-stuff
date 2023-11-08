# frozen_string_literal: true

rule "do stuff because of light during the week" do
  updated Entrance_Luminance

  run do |event|
    current_time = Time.now

    time_range = (Date.today.weekend? ? "9am" : "5:35am").."10:30pm"

    if current_time.between?(time_range)
      if event.state.to_i < 170
        # notify "Turning lights on due to darkness" if Front_Yard_Lights.off?
        Front_Yard_Lights.members.ensure.on
        All_Hall_Lights.members.ensure.on if current_time > LocalTime.parse("9am")
      else
        # notify "Turning lights off due to light" if Front_Yard_Lights.on?
        Front_Yard_Lights.members.ensure.off
        Garage_OutdoorLights_Switch.ensure.off unless Holiday_Mode.state.blank?
        All_Hall_Lights.members.ensure.off
      end
    end
  end

  only_if { Ignore_Luminance.off? }
end
