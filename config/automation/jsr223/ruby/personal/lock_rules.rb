# frozen_string_literal: true

require "homekit"
require "homeseer"
require "lock_events"
require "json"

rule "Front Door Lock: Update lock states after alarm_raw event" do
  changed Front_Door_Lock_Alarm_Raw

  run do |event|
    item = event.item
    basename = item.name[0..-11]
    lock_actual_item = items["#{basename}_Actual"]

    lock_actual_item_homekit = items["#{basename}_Actual_Homekit"]

    alarm = JSON.parse(event.state)

    if alarm["type"] == LockEvents::Type::ACCESS_CONTROL
      case alarm["event"].to_i
      when LockEvents::MANUAL_UNLOCK, LockEvents::REMOTE_UNLOCK
        lock_actual_item.update(OFF)
      when LockEvents::KEYPAD_UNLOCK
        lock_actual_item.update(OFF)

        keycode = alarm[LockEvents::KEYCODE]
        keycode_name = lock_actual_item.thing.configuration.get("usercode_label_#{keycode}")

        logger.warn("#{basename} unlocked by #{keycode_name}")
        notify "#{basename} unlocked by #{keycode_name}"
      when LockEvents::MANUAL_LOCK, LockEvents::KEYPAD_LOCK, LockEvents::REMOTE_LOCK
        lock_actual_item.update(ON)
      when LockEvents::LOCK_JAMMED
        lock_actual_item_homekit.update(Homekit::LockStatus::JAMMED)
      else
        logger.warn("unexpected access event: #{alarm}")
      end
    else
      logger.warn("unexpected alarm type: #{alarm}")
    end
  end
end

rule "Front Door Lock: proxy changes to actual back to target" do
  changed Front_Door_Lock_Actual

  run do |event|
    item = event.item
    basename = item.name[0..-8]
    lock_item = items[basename]
    lock_actual_item_homekit = items["#{basename}_Actual_Homekit"]

    lock_item.update(event.state)
    lock_actual_item_homekit.update(event.state.on? ? Homekit::LockStatus::SECURED : Homekit::LockStatus::UNSECURED)
  end
end

rule "Front Door Lock: proxy lock command" do
  received_command Front_Door_Lock

  run do |event|
    lock_item_actual = items["#{event.item.name}_Actual"]
    lock_item_actual.ensure << event.state
  end
end

rule "when our perimeter has a change" do
  changed House_Perimeter_Contacts, Front_Door_Lock

  run do
    House_Perimeter_LEDs.members.ensure << if House_Perimeter_Contacts.open? || Front_Door_Lock.off?
                                             Homeseer::LedColor::RED
                                           else
                                             Homeseer::LedColor::OFF
                                           end
  end
end
