# frozen_string_literal: true
require 'json'

# This transfomration is set up to ignore NULLs to not pollute the higher levels

# We'll expect input to be the json string, but key will be the key we're looking for in the json string
input ||= nil
key ||= nil

return nil unless input && key

parsed = JSON.parse(input)

result = parsed.dig(*key.split('.'))
return result if result
