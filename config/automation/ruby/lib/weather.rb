# frozen_string_literal: true

require "json"

logger.info("Loading script #{__FILE__}")

# Reference reading material:
# https://climate.umt.edu/mesonet/ag_tools/feels_like/
# https://www.wpc.ncep.noaa.gov/html/heatindex_equation.shtml
# https://www.weather.gov/safety/cold-wind-chill-chart
# https://www.weather.gov/media/epz/wxcalc/windChill.pdf

module Weather
  XWEATHER_OBSERVATIONS_URL = "https://data.api.xweather.com/observations"
  FROST_THRESHOLD_F = 32

  # Xweather coded weather is "coverage:intensity:weather", e.g. "S:H:T"; see
  # https://www.xweather.com/docs/weather-api/reference/weather-codes
  HEAVY_INTENSITIES = %w[H VH].freeze
  LIGHT_INTENSITIES = %w[VL L].freeze
  RAIN_CODES = %w[R RW ZR].freeze
  DRIZZLE_CODES = %w[L ZL].freeze
  SNOW_CODES = %w[S SW BS SI RS WM IP].freeze
  # Present-weather codes with no precipitation; these (and clear skies) are the only ones frost can apply to
  DRY_CODES = %w[F ZF BR H BD BN K].freeze

  class << self
    def feels_like(temp:, humidity:, wind_speed:)
      temp = temp.to_f
      wind_speed = wind_speed.to_i

      result = if temp <= 50 && wind_speed >= 3
                 wind_chill(temp:, wind_speed:)
               elsif temp >= 80
                 heat_index(temp:, humidity: humidity.to_i)
               end

      result&.round(1) || temp
    end

    # Calculates the dew point based on temperature and humidity
    # Formulate from https://en.wikipedia.org/wiki/Dew_point
    # temp is in Fahrenheit
    def dew_point(temp:, humidity:)
      t = f_to_c(temp.to_f)

      n = Math.log(humidity.to_i / 100.0) + ((DP_B * t) / (DP_C + t))
      td = (DP_C * n) / (DP_B - n)

      c_to_f(td).round(1)
    end

    # Fetches the present-weather code for the configured location from Xweather.
    # @return [String, nil] the "coverage:intensity:weather" code ("" when the sky is clear), or nil if the lookup
    #   failed for any reason, so callers can tell "nothing to report" apart from "couldn't find out"
    def current_conditions
      body = post_to_service_frd(
        url: "#{XWEATHER_OBSERVATIONS_URL}/#{secret('weather_location')}",
        params: { client_id: secret("xweather_id"), client_secret: secret("xweather_secret") }
      )
      return if body.nil?

      observation = JSON.parse(body).then { |data| data["success"] && data.dig("response", "ob") }
      return logger.warn("Xweather returned no observation") unless observation

      observation["weatherPrimaryCoded"].to_s
    rescue JSON::ParserError, TypeError => e
      logger.warn("Failed to parse Xweather response: #{e.class}: #{e.message}")
      nil
    end

    # Maps an Xweather present-weather code to an AWTRIX NG weather overlay.
    # @param coded [String, nil] result of {current_conditions}; nil means the lookup failed
    # @param temp_f [Float] outdoor temperature in Fahrenheit, used for frost
    # @return [String, nil] overlay name, or nil when no overlay should be shown
    def overlay_for(coded:, temp_f:)
      return if coded.nil?

      _coverage, intensity, weather = coded.split(":", -1)
      return frost_overlay(temp_f) if weather.blank? || DRY_CODES.include?(weather)

      precipitation_overlay(weather, intensity)
    end

    def post_to_weather_services(params)
      station_id = secret("station_id")
      params[:ID] = station_id

      response = post_to_pwsweather(params: params.dup)
      logger.debug { "PWSWeather response: #{response}" }

      response = post_to_wunderground(params: params.dup)
      logger.debug { "Wunderground response: #{response}" }
    end

    # Constants used in the dew point calculation
    DP_B = 17.625
    DP_C = 243.04

    private

    def secret(key)
      OpenHAB::Core::Actions::Transformation.transform("MAP", "weather_secrets.map", key)
    end

    def frost_overlay(temp_f)
      "frost" if temp_f.to_f <= FROST_THRESHOLD_F
    end

    def precipitation_overlay(weather, intensity)
      if weather == "T"
        "thunder"
      elsif weather == "A"
        "storm"
      elsif RAIN_CODES.include?(weather)
        rain_overlay(intensity)
      elsif DRIZZLE_CODES.include?(weather)
        "drizzle"
      elsif SNOW_CODES.include?(weather)
        "snow"
      end
    end

    def rain_overlay(intensity)
      if HEAVY_INTENSITIES.include?(intensity)
        "storm"
      elsif LIGHT_INTENSITIES.include?(intensity)
        "drizzle"
      else
        "rain"
      end
    end

    # Calculates the head index based on temperature and humidity
    # @param temp [Float] Temperature in Fahrenheit
    # @param humidity [Float] Humidity in percentage
    # @return [Float] The head index
    def heat_index(temp:, humidity:)
      hi = 0.5 * (temp + 61.0 + ((temp - 68.0) * 1.2) + (humidity * 0.094))
      # In practice, the simple formula is computed first and the result averaged with the temperature. If this heat
      # index value is 80 degrees F or higher, the full regression equation along with any adjustment is applied.
      return (hi + temp) / 2 if hi < 80

      hi = -42.379 + (2.04901523 * temp) + (10.14333127 * humidity) - (0.22475541 * temp * humidity) -
           (0.00683783 * temp * temp) - (0.05481717 * humidity * humidity) + (0.00122874 * temp * temp * humidity) +
           (0.00085282 * temp * humidity * humidity) - (0.00000199 * temp * temp * humidity * humidity)
      if humidity < 13 && temp.between?(80, 112)
        hi -= (((13 - humidity) / 4) * Math.sqrt((17 - (temp - 95).abs) / 17))
      elsif humidity > 85 && temp.between?(80, 87)
        hi += (((humidity - 85) / 10) * ((87 - temp) / 5))
      end

      hi
    end

    def wind_chill(temp:, wind_speed:)
      # The formula is only valid for temperatures below 50 degrees F and wind speeds above 3 mph
      return temp if temp > 50 || wind_speed < 3

      wind_pow = wind_speed**0.16
      35.74 + (0.6215 * temp) - (35.75 * wind_pow) + (0.4275 * temp * wind_pow)
    end

    def f_to_c(temp)
      (temp - 32.0) * 5 / 9
    end

    def c_to_f(temp)
      (temp * 9.0 / 5) + 32
    end

    def post_to_pwsweather(params:)
      logger.debug { "Posting to PWSWeather with params: #{params}" }
      params[:PASSWORD] = secret("pws_key")

      post_to_service_frd(url: "https://www.pwsweather.com/pwsupdate/pwsupdate.php", params:)
    end

    def post_to_wunderground(params:)
      params[:action] = "updateraw"
      logger.debug { "Posting to Wunderground with params: #{params}" }

      params[:PASSWORD] = secret("wu_password")

      post_to_service_frd(
        url: "https://weatherstation.wunderground.com/weatherstation/updateweatherstation.php",
        params:
      )
    end

    def post_to_service_frd(url:, params:)
      uri = URI(url)
      uri.query = URI.encode_www_form(params)

      options = { use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5 }
      response = Net::HTTP.start(uri.host, uri.port, options) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
      response.body
    rescue StandardError => e
      logger.warn("Failed to post weather to #{uri.host}: #{e.class}: #{e.message}")
      nil
    end
  end
end
