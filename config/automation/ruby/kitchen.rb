# frozen_string_literal: true

require "zwave"

HIOME_ROOMS_URL = "http://hiome.kgarner.com/api/1/rooms"
BASEMENT_HIOME_ROOM_IDS = %w[1577046124 1557680825 room_1636817791].freeze
HIOME_TIMEOUT_MS = 5000

def reset_basement
  return unless Basement_Total_Occupancy.positive?

  BASEMENT_HIOME_ROOM_IDS.each do |i|
    OpenHAB::Core::Actions::HTTP.sendHttpPutRequest(
      "#{HIOME_ROOMS_URL}/#{i}",
      "application/json",
      %({"occupancy_count": 0}),
      HIOME_TIMEOUT_MS
    )
  rescue StandardError => e
    logger.warn("Failed to reset Hiome occupancy for room #{i}: #{e.class}: #{e.message}")
  end
  Basement_All_Lights.members.ensure.off
end

updated(Kitchen_Accents_Scenes_2.members, to: ZWave::Paddle::TWO_CLICKS) { reset_basement }

updated(Kitchen_Lights_Scenes_1.members, to: [ZWave::Paddle::TWO_CLICKS, ZWave::Paddle::HOLD]) do
  Normal_Kitchen_Lights.members.ensure.on
end

updated(Kitchen_Lights_Scenes_1.members, to: ZWave::Paddle::THREE_CLICKS) { All_Kitchen_Lights.members.ensure.on }

updated(Kitchen_Lights_Scenes_2.members, to: [ZWave::Paddle::TWO_CLICKS, ZWave::Paddle::HOLD]) do
  Normal_Kitchen_Lights.members.ensure.off
end

updated(Kitchen_Lights_Scenes_2.members, to: ZWave::Paddle::THREE_CLICKS) { All_Kitchen_Lights.members.ensure.off }

updated(Kitchen_Lights_Scenes_2.members, to: ZWave::Paddle::FOUR_CLICKS) { reset_basement }
