# frozen_string_literal: true

require "json"
require "homekit"
require "homeseer"
require "kwikset"
require "zwave"
require "tv_notification"
require "awtrix3"
require "active_support/core_ext/hash/indifferent_access"

updated Entrance_FrontDoor_Lock_Alarm_Type, to: [Kwikset::Alarm::KEYPAD_JAMMED,
                                                 Kwikset::Alarm::REMOTE_JAMMED,
                                                 Kwikset::Alarm::AUTO_JAMMED] do
  Front_Door_Lock_Actual_Homekit.update(Homekit::LockStatus::JAMMED)
end

updated Entrance_FrontDoor_Lock_Raw_Notification do |event|
  data = event.state? ? JSON.parse(event.state).with_indifferent_access : {}

  if data[:event] == 6 && data[:type] == 6
    user_id = data.dig("parameters", "userId")
    user = transform("MAP", "lock_user.map", user_id)

    message = "Front Door keypad unlocked by #{user}"

    logger.info(message)
    Notification.send(message)
    TvNotification.notify(message:)
    Awtrix3.new(Office_Awtrix_Clock_Power.thing).show_custom_notification(
      message: message,
      icon: "front_door_lock"
    )
  end

  event.item.ensure.update(NULL)
end

# Front Door Lock: proxy changes to actual back to target
changed(Front_Door_Lock_Actual) do |event|
  item = event.item
  basename = item.name[0..-8]
  lock_item = items[basename]
  lock_actual_item_homekit = items["#{basename}_Actual_Homekit"]

  state = item.state.to_i
  new_state = if ZWave::Lock::Mode::UNSECURED_GROUP.include?(state)
                { state: OFF, homekit: Homekit::LockStatus::UNSECURED }
              elsif state == ZWave::Lock::Mode::SECURED
                { state: ON, homekit: Homekit::LockStatus::SECURED }
              else
                logger.warn("Unknown lock state #{state} for item #{item.name}")
                next
              end

  lock_item.update(new_state[:state])
  lock_actual_item_homekit.update(new_state[:homekit])
end

# Front Door Lock: proxy lock command
received_command(Front_Door_Lock) do |event|
  item = event.item
  lock_item_actual = items["#{item.name}_Actual"]
  target_state = item.state.on? ? ZWave::Lock::Mode::SECURED : ZWave::Lock::Mode::UNSECURED
  lock_item_actual.ensure.command(target_state)
end

changed(House_Perimeter_Contacts, Front_Door_Lock) do |event|
  item = event.item

  color = if House_Perimeter_Contacts.on?
            { homeseer: Homeseer::LedColor::RED, awtrix: Awtrix3::Color::RED }
          elsif Front_Door_Lock.off?
            { homeseer: Homeseer::LedColor::YELLOW, awtrix: Awtrix3::Color::YELLOW }
          else
            { homeseer: Homeseer::LedColor::OFF, awtrix: nil }
          end
  House_Perimeter_LEDs.members.ensure.command(color[:homeseer])

  awtrix = Awtrix3.new(Office_Awtrix_Clock_Power.thing)
  awtrix.set_indicator_color(Awtrix3::INDICATORS[House_Perimeter_Contacts], color[:awtrix])

  print_state = case item
                when Front_Door_Lock
                  item.off? ? "Unlocked" : "Locked"
                when House_Perimeter_Contacts
                  item.on? ? "Open" : "Closed"
                end

  message = "#{item.label} is now #{print_state}"
  awtrix.show_custom_notification(message:, icon: "door", color: color[:awtrix])
  TvNotification.notify(message:, avoid_appletv: (item == Front_Door_Lock))
end

# updated Entrance_FrontDoor_Lock_User_ID_Status_4 do |event|
#   Front_Door_Lock_Cleaning_Switch.ensure.update(event.state.zero? ? OFF : ON)
# end

# changed(Front_Door_Lock_Cleaning_Switch, to: ON) do
#   code = transform("MAP", "lock_code.map", "cleaning")

#   Entrance_FrontDoor_Lock_User_Code_4.ensure.command(code)
# end

# changed(Front_Door_Lock_Cleaning_Switch, to: OFF) do
#   Entrance_FrontDoor_Lock_User_ID_Status_4.ensure.command(0)
# end

# every :thursday, at: "8am" do
#   Front_Door_Lock_Cleaning_Switch.ensure.on
# end

# every :thursday, at: "5pm" do
#   Front_Door_Lock_Cleaning_Switch.ensure.off
# end
