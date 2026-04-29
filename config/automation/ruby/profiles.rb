# frozen_string_literal: true

require "json"

profile(:zwavejs_int_handler) do |event, callback:, state:, configuration:|
  next true unless event == :state_from_handler

  path = configuration.fetch("path", "value")

  result = JSON.parse(state).dig(*path.split("."))&.to_i

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

profile(:adjust_rainin_state) do |event, callback:, state:|
  next true unless event == :state_from_handler

  callback.send_update(state.to_f - 0.05)

  false
end

# Number channel that has 0 for off and 1 for on, but we want to have it as a switch in openHAB
profile(:number_channel_switch) do |event, callback:, state:, command:|
  case event
  when :state_from_handler
    callback.send_update(state == "1" ? ON : OFF)
    false
  when :command_from_item
    callback.handle_command(command == ON ? "1" : "0")
    false
  else
    true
  end
end
