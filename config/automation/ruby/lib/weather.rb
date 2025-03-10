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

    private

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
  end
end
