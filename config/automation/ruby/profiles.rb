# frozen_string_literal: true

require "json"

profile(:zwavejs_int_handler) do |event, callback:, state:, configuration:|
  next true unless event == :state_from_handler

  path = configuration.fetch("path", "value")

  result = JSON.parse(state).dig(*path.split("."))&.to_i

  callback.send_update(result)

  false
end

profile(:zigbee2mqtt_onoff_handler) do |event, callback:, state:|
  next true unless event == :state_from_handler

  result = case state
           when "" then nil
           when "true" then ON
           when "false" then OFF
           end

  callback.send_update(result)

  false
end

profile(:upcase_state) do |event, callback:, state:|
  next true unless event == :state_from_handler

  callback.send_update(state.upcase)

  false
end

profile(:binary_open_state) do |event, callback:, state:|
  next true unless event == :state_from_handler

  callback.send_update(state == "closed" ? OFF : ON)

  false
end
