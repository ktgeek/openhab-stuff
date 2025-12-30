# frozen_string_literal: true

module Awtrix3
  def self.actions(thing)
    thing.actions("mqtt.awtrixlight")
  end

  module Color
    RED = [255, 0, 0].to_java(Java::int).freeze
    GREEN = [0, 255, 0].to_java(Java::int).freeze
    BLUE = [0, 0, 255].to_java(Java::int).freeze
    YELLOW = [255, 255, 0].to_java(Java::int).freeze
    WHITE = [255, 255, 255].to_java(Java::int).freeze
  end
end
