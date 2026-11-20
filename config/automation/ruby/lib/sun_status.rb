# frozen_string_literal: true

# States for the Sun_Status String item, maintained by sun.rb from the entrance luminance sensor.
module SunStatus
  UP = "UP"
  DOWN = "DOWN"

  def self.up?
    ::Sun_Status.state == UP
  end

  def self.down?
    ::Sun_Status.state == DOWN
  end
end
