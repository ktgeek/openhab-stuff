# frozen_string_literal: true

require 'openhab'

rule "check for weather data" do
  changed Backyard_Weather_Updated_At, for: 20.minutes

  run do
    notify "weather hasn't updated in over twenty minutes"
    logger.warn("weather hasn't updated in over 20 minutes")
  end
end
