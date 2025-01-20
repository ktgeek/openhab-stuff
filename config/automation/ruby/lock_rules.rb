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
  user = transform("MAP", "lock_user.map", event.state)

  message = "Front Door keypad unlocked by #{user}"

  logger.info(message)
  Notification.send(message)
end

rule "Front Door Lock: proxy changes to actual back to target" do
  changed Front_Door_Lock_Actual

  run do |event|
    basename = event.item.name[0..-8]
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
    lock_item_actual.ensure.command(event.item.state)
  end
end

rule "when our perimeter has a change" do
  changed House_Perimeter_Contacts, Front_Door_Lock

  run do
    color = if House_Perimeter_Contacts.open?
              Homeseer::LedColor::RED
            elsif Front_Door_Lock.off?
              Homeseer::LedColor::YELLOW
            else
              Homeseer::LedColor::OFF
            end

    House_Perimeter_LEDs.members.ensure.command(color)
  end
end

updated Front_Door_Lock_User_ID_Status_4 do |event|
  Front_Door_Lock_Cleaning_Switch.ensure.update(event.state.zero? ? OFF : ON)
end

changed(Front_Door_Lock_Cleaning_Switch, to: ON) do
  code = transform("MAP", "lock_code.map", "cleaning")

  Front_Door_Lock_User_Code_4.ensure.command(code)
end

changed(Front_Door_Lock_Cleaning_Switch, to: OFF) do
  Front_Door_Lock_User_ID_Status_4.ensure.command(0)
end

every :thursday, at: "8am" do
  Front_Door_Lock_Cleaning_Switch.ensure.on
end

every :thursday, at: "5pm" do
  Front_Door_Lock_Cleaning_Switch.ensure.off
end
