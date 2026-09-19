# frozen_string_literal: true

require "zigbee"

channel(Zigbee::SINGLE_TAP, thing: "homeassistant:device:26bcbec1ee:zigbee2mqtt_5F0x282c02bfffee018b") do
  EvansRoom_LED_Color.toggle
end
