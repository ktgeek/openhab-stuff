# frozen_string_literal: true

require "zwave"

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

updated(FF_Kitchen_Accents_Scenes_2.members, to: ZWave::Paddle::TWO_CLICKS) { reset_basement }

updated(FF_Kitchen_Lights_Scenes_1.members, to: [ZWave::Paddle::TWO_CLICKS, ZWave::Paddle::HOLD]) do
  Normal_Kitchen_Lights.members.ensure.on
end

updated(FF_Kitchen_Lights_Scenes_1.members, to: ZWave::Paddle::THREE_CLICKS) { All_Kitchen_Lights.members.ensure.on }

updated(FF_Kitchen_Lights_Scenes_2.members, to: [ZWave::Paddle::TWO_CLICKS, ZWave::Paddle::HOLD]) do
  Normal_Kitchen_Lights.members.ensure.off
end

updated(FF_Kitchen_Lights_Scenes_2.members, to: ZWave::Paddle::THREE_CLICKS) { All_Kitchen_Lights.members.ensure.off }

updated(FF_Kitchen_Lights_Scenes_2.members, to: ZWave::Paddle::FOUR_CLICKS) { reset_basement }
