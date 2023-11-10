# frozen_string_literal: true

require "homeseer"

def reset_basement
  return unless C_Total_Basement_Occupancy.positive?

  basement_hiome_room_ids = %w[1577046124 1557680825 room_1636817791].freeze

  basement_hiome_room_ids.each do |i|
    OpenHAB::Core::Actions::HTTP.sendHttpPutRequest(
      "http://hiome.kgarner.com/api/1/rooms/#{i}",
      "application/json",
      %({"occupancy_count": 0})
    )
  end
  C_All_Lights.members.ensure.off
end

changed FF_Kitchen_Accents_Scene_Bottom.members, to: Homeseer::PADDLE_TWO_CLICKS do
  reset_basement
end

changed FF_Kitchen_Lights_Scene_Top.members, to: [Homeseer::PADDLE_HOLD, Homeseer::PADDLE_TWO_CLICKS] do
  Normal_Kitchen_Lights.members.ensure.on
end

changed FF_Kitchen_Lights_Scene_Top.members, to: Homeseer::PADDLE_THREE_CLICKS do
  All_Kitchen_Lights.members.ensure.on
end

changed FF_Kitchen_Lights_Scene_Bottom.members, to: [Homeseer::PADDLE_HOLD, Homeseer::PADDLE_TWO_CLICKS] do
  Normal_Kitchen_Lights.members.ensure.off
end

changed FF_Kitchen_Lights_Scene_Bottom.members, to: Homeseer::PADDLE_THREE_CLICKS do
  All_Kitchen_Lights.members.ensure.off
end

changed FF_Kitchen_Lights_Scene_Bottom.members, to: Homeseer::PADDLE_FOUR_CLICKS do
  reset_basement
end
