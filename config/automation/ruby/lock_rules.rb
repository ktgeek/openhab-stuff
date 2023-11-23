# frozen_string_literal: true

require "homekit"
require "homeseer"
require "kwikset"
require "json"

updated Front_Door_Lock_Alarm_Type, to: [Kwikset::Alarm::KEYPAD_JAMMED,
                                         Kwikset::Alarm::REMOTE_JAMMED,
                                         Kwikset::Alarm::AUTO_JAMMED] do
  Front_Door_Lock_Actual_Homekit.update(Homekit::LockStatus::JAMMED)
end

updated Front_Door_Lock_Keypad_Unlock_UserId do |event|
  # TODO: Add some mapping to get the user name of whoever unlocked the door

  # this is old code, just kept for reference for now
  # keycode_name = lock_actual_item.thing.configuration.get("usercode_label_#{keycode}")

  user_id = event.state

  logger.info("Front Door Keypad Unlock User ID: #{user_id}")
  notify "Front Door unlocked by user id: #{user_id}"

  # logger.warn("#{basename} unlocked by #{keycode_name}")
  # notify "#{basename} unlocked by #{keycode_name}"
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
    lock_item_actual.ensure << event.item.state
  end
end

rule "when our perimeter has a change" do
  changed House_Perimeter_Contacts, Front_Door_Lock

  run do
    House_Perimeter_LEDs.members.ensure << if House_Perimeter_Contacts.open?
                                             Homeseer::LedColor::RED
                                           elsif Front_Door_Lock.off?
                                             Homeseer::LedColor::YELLOW
                                           else
                                             Homeseer::LedColor::OFF
                                           end
  end
end
