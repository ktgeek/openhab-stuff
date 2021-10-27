# frozen_string_literal: true

logger.info("Loading script #{__FILE__}")

module WifiLED
  module Program
    NO_PROGRAM = 97

    FADE = 37
    RED_FADE= 38
    GREEN_FADE = 39
    BLUE_FADE = 40
    YELLOW_FADE = 41
    CYAN_FADE = 42
    PURPLE_FADE = 43
    WHITE_FADE = 44
    RED_GREEN_CROSSFADE = 45
    RED_BLUE_CROSSFADE = 46
    BLUE_GREEN_CROSSFADE = 47

    ALL_COLORS_STROBE = 48
    RED_STROBE = 49
    GREEN_STROBE = 50
    BLUE_STROBE = 51
    YELLOW_STROBE = 52
    CYAN_STROBE = 53
    PURPLE_STROBE = 54
    WHITE_STROBE = 55

    ALL_COLORS_JUMP = 56
  end


  module Color
    # color is a 360 value, then saturation and brighteness.  This is FULL RED
    #RED = "0,100,100"
    #RED = "#ff0000"
    RED = OpenHAB::DSL::Types::HSBType.new(0, 100, 100)
  end
end
