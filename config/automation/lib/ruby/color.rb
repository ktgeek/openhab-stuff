# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

# Defining some colors I use a lot
module Color
  # color is a 360 value, then saturation and brighteness.  This is FULL RED
  RED = OpenHAB::DSL::Types::HSBType.new(0, 100, 100)
  WARM_WHITE = OpenHAB::DSL::Types::HSBType.new(44, 13, 100)
end
