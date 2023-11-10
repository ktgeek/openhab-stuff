# frozen_string_literal: true

require 'json'

profile(:zwavejs_int_handler) do |event, callback:, state:, configuration:|
  next true unless event == :state_from_handler

  path = configuration.fetch("path", "value")

  result = JSON.parse(state).dig(*path.split("."))&.to_i

  callback.send_update(result)

  false
end
