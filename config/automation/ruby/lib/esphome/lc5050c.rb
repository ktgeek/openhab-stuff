# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module Esphome
  module LC5050C
    module Palette
      RED_GREEN_CROSSFADE = "#FF0000 #000000 #00FF00 #000000"
      PURPLE_FADE = "#FF00FF #000000"
      RED_WHITE_BLUE_CROSSFADE = "#FF0000 #000000 #FFFFFF #000000 #0000FF"
    end

    module Effects
      SINGLE_COLOR = "None"
      WAKEUP = "Wakeup"
      CYCLE_UP = "Palette Cycle Up"
      CYCLE_DOWN = "Palette Cycle Down"
      PURPLE_FADE = "Purple Fade"
      RED_GREEN_CROSSFADE = "Red Green Crossfade"
      RED_WHITE_BLUE_CROSSFADE = "Red White Blue Crossfade"
    end
  end
end
