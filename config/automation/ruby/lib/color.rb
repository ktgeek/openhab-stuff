# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

# Defining some colors I use a lot
module Color
  # color is a 360 value, then saturation and brightness.  This is FULL RED
  RED = OpenHAB::Core::Types::HSBType.new(0, 100, 100)
  WARM_WHITE = OpenHAB::Core::Types::HSBType.new(44, 13, 100)
  PURPLE = OpenHAB::Core::Types::HSBType.new(300, 100, 100)
  GREEN = OpenHAB::Core::Types::HSBType.new(120, 100, 100)

  # Temperatures (°F) at and beyond which the temperature scale stops changing
  COLDEST_TEMP = -10
  HOTTEST_TEMP = 90

  # Sweeps the hue from deep blue (240) at COLDEST_TEMP, through cyan, green and yellow, to red (0) at HOTTEST_TEMP.
  def self.for_temperature(temp)
    clamped = temp.to_f.clamp(COLDEST_TEMP, HOTTEST_TEMP)
    hue = 240 * (HOTTEST_TEMP - clamped) / (HOTTEST_TEMP - COLDEST_TEMP)
    OpenHAB::Core::Types::HSBType.new(hue, 100, 100)
  end
end
