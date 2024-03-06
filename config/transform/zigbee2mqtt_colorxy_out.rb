# frozen_string_literal: true

require "json"

input ||= nil

x, y, brightness = input.split(",")

result = { "color" => { "x" => x, "y" => y } }
# Brightness comes in as a precentage, we need to scale it to 0-254
result["brightness"] = (brightness.to_f * 2.54)

result.to_json
