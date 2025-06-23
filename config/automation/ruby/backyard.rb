# frozen_string_literal: true

require "zwave"
require "weather"

no_update_notification_sent = false

channel("scene_1", thing: Kitchen_Backyard_Lights_Switch.thing, triggered: ZWave::Paddle::CLICK) do
  Backyard_Lights_Power.ensure.on
end
channel("scene_2", thing: Kitchen_Backyard_Lights_Switch.thing, triggered: ZWave::Paddle::CLICK) do
  Backyard_Lights_Power.ensure.off
end

changed(Backyard_Temperature, Backyard_Humidity, Backyard_Wind_Speed) do
  after(3.seconds, id: "update_feels_like", reschedule: false) do
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
  after(3.seconds, id: "update_dew_point", reschedule: false) do
    Backyard_Dew_Point.update(Weather.dew_point(temp: Backyard_Temperature.state, humidity: Backyard_Humidity.state))
  end
end

every 1.minute do
  last_update = Backyard_Last_Updated.state

  if last_update < 2.hours.ago && !no_update_notification_sent
    logger.info("Backyard weather not updated in hours, last update: #{last_update}")
    Notification.send("Backyard weather not updated in hours, last update: #{last_update}")
    no_update_notification_sent = true
  end

  next if last_update < 1.minute.ago

  no_update_notification_sent = false

  params = {
    dateutc: Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"),
    tempf: Backyard_Temperature.state.to_f,
    humidity: Backyard_Humidity.state.to_i,
    baromin: Backyard_Barometric_Pressure.state.to_f,
    winddir: Backyard_Wind_Direction.state.to_i,
    windspeedmph: Backyard_Wind_Speed.state.to_f,
    windspdmph_avg2m: Backyard_Wind_Speed.average_since(2.minutes.ago).to_f,
    windgustmph: Backyard_Wind_Speed.maximum_since(60.minutes.ago).to_f,
    rainin: Backyard_Rain.sum_since(1.hour.ago).to_i,
    dewptf: Backyard_Dew_Point.state.to_f,
    dailyrainin: Backyard_Rain.sum_since(LocalTime::MIDNIGHT).to_i,
    UV: Backyard_UV.state.to_i
  }
  Weather.post_to_weather_services(params)
end
