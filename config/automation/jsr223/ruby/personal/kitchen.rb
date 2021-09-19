# frozen_string_literal: true

require 'openhab'

$LOAD_PATH.unshift(ENV["RUBYLIB"]) if ENV["RUBYLIB"]
require 'homeseer'

def reset_basement
  return unless C_Total_Basement_Occupancy > 0
  basement_hiome_room_ids = %w/1577046124 1557680825/.freeze

  basement_hiome_room_ids.each do |i|
    HTTP::sendHttpPutRequest("http://hiome.kgarner.com/api/1/rooms/#{i}", "application/json", '{"occupancy_count": 0}')
  end
  C_All_Lights.members.each { |i| i.off if i.off? }
end

rule "when the kitchen accent switchs have a scene change" do
  updated FF_Kitchen_Accents_Scene.members

  run do |event|
    case(event.state)
    when Homeseer::PADDLE_DOWN_TWO_CLICKS
      reset_basement
    end
  end
end

rule "when ktich lights scene change" do
  updated FF_Kitchen_Accents_Scene.members

  run do |event|
    case(event.state)
    when Homeseer::PADDLE_UP_HOLD || Homeseer::PADDLE_UP_TWO_CLICKS
      Normal_Kitch_Lights.members.each { |i| i.on unless i.on? }
    when Homeseer::PADDLE_DOWN_HOLE || Homeseer::PADDLE_DOWN_TWO_CLICKS
      Normal_Kitch_Lights.members.each { |i| i.off unless i.off? }
    when Homeseer::PADDLE_UP_THREE_CLICKS
      ALL_KITCHEN_LIGHTS.members.each { |i| i.on unless i.on? }
    when Homeseer::PADDLE_DOWN_THREE_CLICKS
      All_Kitchen_Lights.members.each { |i| i.off unless i.off? }
    when Homeseer::PADDLE_DOWN_FOUR_CLICKS
      reset_basement
    end
  end
end
