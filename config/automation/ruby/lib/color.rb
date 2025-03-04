# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

# Defining some colors I use a lot
module Color
  # color is a 360 value, then saturation and brighteness.  This is FULL RED
  RED = OpenHAB::Core::Types::HSBType.new(0, 100, 100)
  WARM_WHITE = OpenHAB::Core::Types::HSBType.new(44, 13, 100)
  PURPLE = OpenHAB::Core::Types::HSBType.new(300, 100, 100)
  GREEN = OpenHAB::Core::Types::HSBType.new(120, 100, 100)
end
