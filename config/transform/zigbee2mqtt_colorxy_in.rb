# frozen_string_literal: true

require "json"

input ||= nil

data = JSON.parse(input)
# brightness is a value from 0 to 254, but we need a percent.
brightness = (data["brightness"].to_f / 254.0 * 100.0).round

"#{data.dig('color', 'x')},#{data.dig('color', 'y')},#{brightness}"
