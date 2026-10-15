# frozen_string_literal: true

require "awtrix3"

# Clock-neutral pieces shared by the Awtrix 3 and AWTRIX NG libraries, so rules describe a notification or an
# indicator once and every clock shows it.
module Awtrix
  INDICATORS = {
    ::Garage_LargeDoor => 1,
    ::Garage_SmallDoor => 2,
    ::House_Perimeter_Contacts => 3
  }.freeze

  # Plain [r, g, b] arrays; each clock library converts them to what its binding wants.
  module Color
    RED = [255, 0, 0].freeze
    GREEN = [0, 255, 0].freeze
    BLUE = [0, 0, 255].freeze
    YELLOW = [255, 255, 0].freeze
    WHITE = [255, 255, 255].freeze
  end

  # Forwards each call to every clock, with the same interface as a single clock.
  class ClockGroup
    def initialize(clocks)
      @clocks = clocks
    end

    def show_custom_notification(...)
      @clocks.each { |clock| clock.show_custom_notification(...) }
    end

    def set_indicator_color(...)
      @clocks.each { |clock| clock.set_indicator_color(...) }
    end
  end

  def self.all_clocks
    @all_clocks ||= ClockGroup.new([Awtrix3.office_clock])
  end
end
