# frozen_string_literal: true

module ZWave
  # This appear to be common scene values across zwave devices via zwavejs-ui
  module Paddle
    CLICK = 0
    RELEASE = 1
    HOLD = 2
    TWO_CLICKS = 3
    THREE_CLICKS = 4
    FOUR_CLICKS = 5
    FIVE_CLICKS = 6
  end

  module Thermostat
    module Mode
      OFF = 0
      HEAT = 1
      COOL = 2
      AUTO = 3
      AUX = 4
      RESUME = 5
      FAN_ONLY = 6
      FURNACE = 7
      DRY = 8
      MOIST = 9
      AUTO_CHANGEOVER = 10
      ENERGY_HEAT = 11
      ENERGY_COOL = 12
      AWAY = 13
      # 14 is undefined (No Z-Wave mode 0x0e)
      FULL_POWER = 15
    end

    module State
      IDLE = 0
      HEATING = 1
      COOLING = 2
      FAN = 3
      IDLE_4 = 4
      IDLE_5 = 5
      FAN_6 = 6
      HEATING_7 = 7
      HEATING_8 = 8
      COOLING_9 = 9
    end
  end
end
