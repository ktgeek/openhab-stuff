# frozen_string_literal: true

rule "Hall Lights follow" do
  changed All_Hall_Lights.members

  run { |event| All_Hall_Lights.members.ensure << event.state }
end

rule "do stuff because of light during the week" do
  updated Entrance_Luminance

  run do |event|
    current_time = Time.now

    time_range = (Date.today.weekend? ? "9am" : "5:50am").."10:30pm"

    if current_time.between?(time_range)
      if event.state < 170
        # notify "Turning lights on due to darkness" if Front_Yard_Lights.off?
        Front_Yard_Lights.members.ensure.on
        All_Hall_Lights.members.ensure.on if current_time > LocalTime.parse("9am")
      else
        # notify "Turning lights off due to light" if Front_Yard_Lights.on?
        Front_Yard_Lights.members.ensure.off
        All_Hall_Lights.members.ensure.off
      end
    end
  end
end
