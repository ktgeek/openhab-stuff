# frozen_string_literal: true
require 'openhab'

$LOAD_PATH.unshift(ENV["RUBYLIB"]) if ENV["RUBYLIB"]
require 'homeseer'

# on_start is trigger for init

# def garage_door_status(item)
#   item != "closed" ? [1, "opened"] : [2, "closed"]
# end

# rule "when the large garage door changes status" do
#   changed Large_Garage_Door_Status

#   run do
#     led, name = garage_door_status(Large_Garage_Door_Status)

#     Large_Garage_Door_Open_LEDs.members.each { |i| i << led unless i == led }
#     TV_Notifications << "Large Garage Door #{name}"
#   end
# end

# rule "when the small garage door changes status" do
#   changed Small_Garage_Door_Status

#   run do
#     led, name = garage_door_status(Small_Garage_Door_Status)

#     Small_Garage_Door_Open_LEDs.members.each { |i| i << led unless i == led }
#     TV_Notifications << "Small Garage Door #{name}"
#   end
# end

rule "Garage Doors Change State" do
  changed [Large_Garage_Door_Status, Small_Garage_Door_Status]

  triggered do |item|
    underscore_label = item.label.tr(" ", "_")
    leds = items["#{underscore_label}_Open_LEDs"]

    color, status_text = item != "closed" ? [Homeseer::Led_Color::RED, "opened"] : [Homeseer::Led_Color::GREEN, "closed"]

    leds.members.each { |i| i << color unless i == color }
    TV_Notifications << "#{item.label} #{status_text}"
  end
end
