# frozen_string_literal: true

require "zwave"

RSpec.describe "living_room.rb" do
  describe "scene switch paddles" do
    {
      "LivingRoom_Scene_Switch_Scene_1" => "LivingRoom_Light_2_Color",
      "LivingRoom_Scene_Switch_Scene_2" => "LivingRoom_Light_1_Color",
      "LivingRoom_Scene_Switch_Scene_3" => "LivingRoom_WallOutlet_Switch",
      "LivingRoom_Scene_Switch_Scene_4" => "LivingRoom_TableLight_Switch"
    }.each do |scene_name, target_name|
      context "when #{scene_name} is clicked" do
        let(:scene) { items[scene_name] }
        let(:target) { items[target_name] }
        let(:off_state) { target.is_a?(OpenHAB::Core::Items::ColorItem) ? HSBType.new(0, 0, 0) : OFF }

        before do
          target.update(off_state)
          scene.update(ZWave::Paddle::CLICK)
        end

        it "turns #{target_name} on" do
          expect(target).to be_on
        end

        it "turns #{target_name} back off on the next click" do
          scene.update(ZWave::Paddle::CLICK)

          expect(target).to be_off
        end
      end
    end
  end
end
