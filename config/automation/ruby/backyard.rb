# frozen_string_literal: true

require "zwave"
require "weather"

BACKYARD_LIGHT_SWITCHES = [Kitchen_Backyard_Lights_Switch.thing, FamilyRoom_Backyard_Lights_Switch.thing].freeze

channel("scene_1", thing: BACKYARD_LIGHT_SWITCHES, triggered: ZWave::PADDLE_CLICK) { Backyard_Lights_Power.ensure.on }

channel("scene_2", thing: BACKYARD_LIGHT_SWITCHES, triggered: ZWave::PADDLE_CLICK) { Backyard_Lights_Power.ensure.off }

changed(Backyard_Temperature, Backyard_Humidity, Backyard_Wind_Speed) do
  Backyard_FeelsLike_Temperature.update(
    Weather.feels_like(
      temp: Backyard_Temperature.state,
      humidity: Backyard_Humidity.state,
      wind_speed: Backyard_Wind_Speed.state
    )
  )
end
