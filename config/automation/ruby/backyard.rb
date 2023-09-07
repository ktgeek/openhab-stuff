# frozen_string_literal: true

rule "Backyard lights follow" do
  changed Backyard_Lights.members

  run { |event| Backyard_Lights.members.ensure << event.state }
end

# rule "check for weather data" do
#   changed Backyard_Weather_Updated_At, for: 40.minutes

#   run do
#     notify "weather hasn't updated in over forty minutes"
#     logger.warn("weather hasn't updated in over 40 minutes")
#   end
# end
