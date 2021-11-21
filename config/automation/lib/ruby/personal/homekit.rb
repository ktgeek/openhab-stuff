# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module Homekit
  module LockStatus
    OFF = 0
    UNSECURED = 0
    ON = 1
    SECURED = 1
    JAMMED = 2
    UNKNOWN = 3
  end
end
