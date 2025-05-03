# frozen_string_literal: true

logger.info("Loading script #{__FILE__}")

# Reference reading material:
# https://climate.umt.edu/mesonet/ag_tools/feels_like/
# https://www.wpc.ncep.noaa.gov/html/heatindex_equation.shtml
# https://www.weather.gov/safety/cold-wind-chill-chart
# https://www.weather.gov/media/epz/wxcalc/windChill.pdf

module Weather
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

    def post_to_weather_services(params)
      station_id = OpenHAB::Core::Actions::Transformation.transform("MAP", "weather_secrets.map", "station_id")
      response = post_to_pwsweather(station_id:, params: )
      logger.info("PWSWeather response: #{response}")

    end

    private

    # Constants used in the dew point calculation
    DP_B = 17.625
    DP_C = 243.04

    # Calculates the head index based on temperature and humidity
    # @param temp [Float] Temperature in Fahrenheit
    # @param humidity [Float] Humidity in percentage
    # @return [Float] The head index
    def heat_index(temp:, humidity:)
      hi = 0.5 * (temp + 61.0 + ((temp - 68.0) * 1.2) + (humidity * 0.094))
      # In practice, the simple formula is computed first and the result averaged with the temperature. If this heat
      # index value is 80 degrees F or higher, the full regression equation along with any adjustment is applied.
      return ((hi + temp) / 2) if hi < 80

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
    def post_to_pwsweather(station_id:, params:)
      params[:ID] = station_id
      params[:PASSWORD] = OpenHAB::Core::Actions::Transformation.transform("MAP", "weather_secrets.map", "pws_key")

      url = URI("https://pwsupdate.pwsweather.com/api/v1/submitwx")
      url.query = URI.encode_www_form(params)

      response = Net::HTTP.get_response(url)
      response.body
    end

  end
end
