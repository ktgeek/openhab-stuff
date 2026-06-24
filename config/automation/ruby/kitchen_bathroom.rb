# frozen_string_literal: true

changed(KitchenBathroom_ContactSensor, to: ON) do
  timers.cancel(KitchenBathroom_Light_Switch)
  timers.cancel(KitchenBathroom_Fan_Switch)

  after(2.minutes, id: KitchenBathroom_Light_Switch) { KitchenBathroom_Light_Switch.ensure.off }
  after(5.minutes, id: KitchenBathroom_Fan_Switch) { KitchenBathroom_Fan_Switch.ensure.off }
end

changed(KitchenBathroom_ContactSensor, to: OFF) do
  timers.cancel(KitchenBathroom_Light_Switch)
  timers.cancel(KitchenBathroom_Fan_Switch)
end
