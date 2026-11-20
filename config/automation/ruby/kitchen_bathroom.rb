# frozen_string_literal: true

# `for:` only fires if the sensor is still ON after the delay, so it drops the pending turn-off by itself when the
# sensor goes OFF.
changed(KitchenBathroom_ContactSensor, to: ON, for: 2.minutes) { KitchenBathroom_Light_Switch.ensure.off }

changed(KitchenBathroom_ContactSensor, to: ON, for: 5.minutes) { KitchenBathroom_Fan_Switch.ensure.off }
