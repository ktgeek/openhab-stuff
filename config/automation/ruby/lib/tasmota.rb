# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module Tasmota
  module Palette
    RED_GREEN_CROSSFADE = "#FF0000 #000000 #00FF00 #000000"
    PURPLE_FADE = "#FF00FF #000000"
    RED_WHITE_BLUE_CROSSFADE = "#FF0000 #000000 #FFFFFF #000000 #0000FF"
  end

  module Scheme
    SINGLE_COLOR = 0
    WAKEUP = 1
    CYCLE_UP = 2
    CYCLE_DOWN = 3
  end
end
