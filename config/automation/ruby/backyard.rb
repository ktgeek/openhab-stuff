# frozen_string_literal: true

require "zwave"
require "weather"

no_update_notification_sent = false

updated Kitchen_Backyard_Lights_Scene_1, to: ZWave::Paddle::CLICK do
  Backyard_Lights_Color.ensure.on
end

updated Kitchen_Backyard_Lights_Scene_2, to: ZWave::Paddle::CLICK do
  Backyard_Lights_Color.ensure.off
end

changed(Backyard_Temperature, Backyard_Humidity, Backyard_Wind_Speed) do
  after(3.seconds, id: "update_feels_like", reschedule: false) do
    temp = Weather.feels_like(
      temp: Backyard_Temperature.state,
      humidity: Backyard_Humidity.state,
      wind_speed: Backyard_Wind_Speed.state
    )
    Backyard_FeelsLike_Temperature.update(temp)
    outdoor_temp_text = "#{temp}#{'°F' if temp < 100}"
    [Office_Awtrix_OutdoorTemp_Text, Bedroom_Awtrix_OutdoorTemp_Text].each do |item|
      item.ensure.command(outdoor_temp_text)
    end
  end
end

changed(Backyard_Temperature, Backyard_Humidity) do
  after(3.seconds, id: "update_dew_point", reschedule: false) do
    Backyard_Dew_Point.update(Weather.dew_point(temp: Backyard_Temperature.state, humidity: Backyard_Humidity.state))
  end
end

every 1.minute do
  last_update = Backyard_Last_Updated.state

  # NULL/UNDEF until the weather station reports after a fresh start
  next if last_update.nil?

  if last_update < 2.hours.ago && !no_update_notification_sent
    logger.info("Backyard weather not updated in hours, last update: #{last_update}")
    Notification.send("Backyard weather not updated in hours, last update: #{last_update}")
    no_update_notification_sent = true
  end

  next if last_update < 1.minute.ago

  no_update_notification_sent = false

  next unless [Backyard_Temperature, Backyard_Humidity, Backyard_Barometric_Pressure, Backyard_Wind_Direction,
               Backyard_Wind_Speed, Backyard_Dew_Point, Backyard_UV].all?(&:state?)

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

# The AWTRIX NG overlay channel is cleared with an empty string
NO_OVERLAY = ""

# Weather conditions come only from Xweather. When the lookup fails the condition item is cleared and so is the overlay,
# rather than leaving a stale one on the clock.
rule "Update bedroom weather overlay", id: "backyard_weather_overlay" do
  every 10.minutes
  on_start
  run do
    coded = Weather.current_conditions
    Backyard_Weather_Condition.update(coded || NULL)

    temp_f = Backyard_Temperature.state.to_f if Backyard_Temperature.state?
    overlay = Weather.overlay_for(coded:, temp_f:)
    Bedroom_AwtrixClock_Overlay.ensure.command(overlay || NO_OVERLAY)
  end
end
