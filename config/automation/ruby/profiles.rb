# frozen_string_literal: true

require 'json'

profile(:zwavejs_scene_handler) do |event, callback:, state:|
  next true unless event == :state_from_handler

  result = JSON.parse(state).dig("value")&.to_i

  callback.send_update(result)

  false
end
