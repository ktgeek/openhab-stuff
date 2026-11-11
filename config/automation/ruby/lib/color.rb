# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

# Defining some colors I use a lot
module Color
  # color is a 360 value, then saturation and brightness.  This is FULL RED
  RED = OpenHAB::Core::Types::HSBType.new(0, 100, 100)
  WARM_WHITE = OpenHAB::Core::Types::HSBType.new(44, 13, 100)
  PURPLE = OpenHAB::Core::Types::HSBType.new(300, 100, 100)
  GREEN = OpenHAB::Core::Types::HSBType.new(120, 100, 100)

  # [temperature (°F), hue] points the temperature scale passes through, coldest first. The scale stops changing at
  # the first and last temperatures. Freezing is pinned to a cyan-blue (185) with the deeper blues saved for below it,
  # so the cold end is compressed relative to the rest of the scale.
  TEMPERATURE_HUES = [[-10, 245], [32, 185], [100, 0]].freeze

  # Sweeps the hue from deep blue at the coldest point, through cyan, green and yellow, to red at the hottest,
  # interpolating linearly between the points in TEMPERATURE_HUES.
  #
  # The result is snapped to 8-bit RGB. The clocks only take #rrggbb and the item reports its state back from that
  # hex, so a finer hue would never equal the reported state and `ensure` would re-send the command every time.
  def self.for_temperature(temp)
    clamped = temp.to_f.clamp(TEMPERATURE_HUES.first.first, TEMPERATURE_HUES.last.first)
    (cold_temp, cold_hue), (hot_temp, hot_hue) =
      TEMPERATURE_HUES.each_cons(2).find { |_, (upper_temp, _)| clamped <= upper_temp }
    hue = cold_hue + ((hot_hue - cold_hue) * (clamped - cold_temp) / (hot_temp - cold_temp))
    OpenHAB::Core::Types::HSBType.new(OpenHAB::Core::Types::HSBType.new(hue, 100, 100).to_hex)
  end
end
