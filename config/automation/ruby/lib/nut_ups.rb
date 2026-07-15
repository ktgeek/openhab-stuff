# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module NutUps
  # NUT (Network UPS Tools) ups.status flag values.
  # Code     Description
  # OL       On line (mains is present)
  # OB       On battery (mains is not present)
  # LB       Low battery
  # HB       High battery
  # RB       The battery needs to be replaced
  # CHRG     The battery is charging
  # DISCHRG  The battery is discharging (inverter is providing load power)
  # BYPASS   UPS bypass circuit is active -- no battery protection is available
  # CAL      UPS is currently performing runtime calibration (on battery)
  # OFF      UPS is offline and is not supplying power to the load
  # OVER     UPS is overloaded
  # TRIM     UPS is trimming incoming voltage (called "buck" in some hardware)
  # BOOST    UPS is boosting incoming voltage
  # FSD      Forced Shutdown (restricted use, see the note below)
  module Status
    ON_LINE = "OL"
    ON_BATTERY = "OB"
    LOW_BATTERY = "LB"
    HIGH_BATTERY = "HB"
    REPLACE_BATTERY = "RB"
    CHARGING = "CHRG"
    DISCHARGING = "DISCHRG"
    BYPASS = "BYPASS"
    CALIBRATING = "CAL"
    OFFLINE = "OFF"
    OVERLOADED = "OVER"
    TRIMMING = "TRIM"
    BOOSTING = "BOOST"
    FORCED_SHUTDOWN = "FSD"
  end
end
