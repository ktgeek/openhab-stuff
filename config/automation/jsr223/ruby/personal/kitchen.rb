# frozen_string_literal: true

require "homeseer"

def reset_basement
  return unless C_Total_Basement_Occupancy.positive?

  basement_hiome_room_ids = %w[1577046124 1557680825 room_1636817791].freeze

  basement_hiome_room_ids.each do |i|
    OpenHAB::Core::Actions::HTTP.sendHttpPutRequest(
      "http://hiome.kgarner.com/api/1/rooms/#{i}",
      "application/json",
      '{"occupancy_count": 0}'
    )
  end
  C_All_Lights.members.ensure.off
end

rule "when the kitchen accent switches have a scene change" do
  updated FF_Kitchen_Accents_Scene.members

  run { |event| reset_basement if event.state == Homeseer::PADDLE_DOWN_TWO_CLICKS }
end

rule "when kitchen lights scene change" do
  updated FF_Kitchen_Lights_Scene.members

  run do |event|
    case event.state
    when Homeseer::PADDLE_UP_HOLD, Homeseer::PADDLE_UP_TWO_CLICKS
      Normal_Kitchen_Lights.members.ensure.on
    when Homeseer::PADDLE_DOWN_HOLD, Homeseer::PADDLE_DOWN_TWO_CLICKS
      Normal_Kitchen_Lights.members.ensure.off
    when Homeseer::PADDLE_UP_THREE_CLICKS
      All_Kitchen_Lights.members.ensure.on
    when Homeseer::PADDLE_DOWN_THREE_CLICKS
      All_Kitchen_Lights.members.ensure.off
    when Homeseer::PADDLE_DOWN_FOUR_CLICKS
      reset_basement
    end
  end
end
