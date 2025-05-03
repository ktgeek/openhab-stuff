# frozen_string_literal: true

require "zwave"
require "weather"

BACKYARD_LIGHT_SWITCHES = [Kitchen_Backyard_Lights_Switch.thing, FamilyRoom_Backyard_Lights_Switch.thing].freeze

channel("scene_1", thing: BACKYARD_LIGHT_SWITCHES, triggered: ZWave::Paddle::CLICK) { Backyard_Lights_Power.ensure.on }

channel("scene_2", thing: BACKYARD_LIGHT_SWITCHES, triggered: ZWave::Paddle::CLICK) { Backyard_Lights_Power.ensure.off }

rule "core weather data has changed" do
  changed Backyard_Temperature, Backyard_Humidity, Backyard_Wind_Speed

  delay 3.seconds
  run do
    Backyard_FeelsLike_Temperature.update(
      Weather.feels_like(
        temp: Backyard_Temperature.state,
        humidity: Backyard_Humidity.state,
        wind_speed: Backyard_Wind_Speed.state
      )
    )
  end
end

changed(Backyard_Temperature, Backyard_Humidity) do
  Backyard_Dew_Point.update(Weather.dew_point(temp: Backyard_Temperature.state, humidity: Backyard_Humidity.state))
end

every 1.minute do
  params = {
    dateutc: Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"),
    tempf: Backyard_Temperature.state.to_f,
    humidity: Backyard_Humidity.state.to_i,
    baromin: Backyard_Barometric_Pressure.state.to_f,
    winddir: Backyard_Wind_Direction.state.to_i,
    windspeedmph: Backyard_Wind_Speed.average_since(2.minutes.ago).to_f,
    windgustmph: Backyard_Wind_Speed.maximum_since(60.minutes.ago).to_f,
    rainin: Backyard_Rain.sum_since(1.hour.ago).to_i,
    dewptf: Backyard_Dew_Point.state.to_f,
    dailyrainin: Backyard_Rain.sum_since(LocalTime::MIDNIGHT).to_i,
    UV: Backyard_UV.state.to_i
  }
  Weather.post_to_weather_services(params)
end
