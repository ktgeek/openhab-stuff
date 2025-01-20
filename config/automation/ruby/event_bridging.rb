# frozen_string_literal: true

require "zigbee"

Zigbee::Remote.event("Remote Button Press") do |label, action|
  sanatized = label.strip.tr(" ", "_")
  items["#{sanatized}_Action"]&.command(action)
end
