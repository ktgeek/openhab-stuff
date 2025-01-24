# frozen_string_literal: true

logger.info("Loading script #{__FILE__}")

module Zigbee
  # Events
  SINGLE_TAP = "single"
  DOUBLE_TAP = "double"
  TRIPLE_TAP = "triple"
  QUADRUPLE_TAP = "quadruple"
  QUINTUPLE_TAP = "quintuple"
  HOLD = "hold"
  RELEASE = "release"
end
