# frozen_string_literal: true

input ||= nil

input.to_f.positive? ? "ON" : "OFF"
