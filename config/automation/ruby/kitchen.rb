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

channel("scene_2", thing: FF_Kitchen_Accents_Scene.members.map(&:thing), triggered: ZWave::Paddle::TWO_CLICKS) do
  reset_basement
end

channel("scene_1", thing: FF_Kitchen_Lights_Scene.members.map(&:thing),
                   triggered: [ZWave::Paddle::TWO_CLICKS, ZWave::Paddle::HOLD]) do
  Normal_Kitchen_Lights.members.ensure.on
end

channel("scene_1", thing: FF_Kitchen_Lights_Scene.members.map(&:thing), triggered: ZWave::Paddle::THREE_CLICKS) do
  All_Kitchen_Lights.members.ensure.on
end

channel("scene_2", thing: FF_Kitchen_Lights_Scene.members.map(&:thing),
                   triggered: [ZWave::Paddle::TWO_CLICKS, ZWave::Paddle::HOLD]) do
  Normal_Kitchen_Lights.members.ensure.off
end

channel("scene_2", thing: FF_Kitchen_Lights_Scene.members.map(&:thing), triggered: ZWave::Paddle::THREE_CLICKS) do
  All_Kitchen_Lights.members.ensure.off
end

channel("scene_2", thing: FF_Kitchen_Lights_Scene.members.map(&:thing), triggered: ZWave::Paddle::FOUR_CLICKS) do
  reset_basement
end
