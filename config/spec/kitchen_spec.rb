# frozen_string_literal: true

require "zwave"

RSpec.describe "kitchen.rb" do
  let(:hiome_urls) { BASEMENT_HIOME_ROOM_IDS.map { |id| "#{HIOME_ROOMS_URL}/#{id}" } }

  before { allow(OpenHAB::Core::Actions::HTTP).to receive(:sendHttpPutRequest) }

  def set_all(group, state)
    suspend_rules { group.members.each { |item| item.update(state) } }
  end

  describe "kitchen light paddle" do
    { "two clicks" => ZWave::Paddle::TWO_CLICKS, "a hold" => ZWave::Paddle::HOLD }.each do |description, click|
      it "turns the normal kitchen lights on with #{description} of the top paddle" do
        set_all(All_Kitchen_Lights, OFF)
        Kitchen_Lights_Scene_1.update(click)

        expect(Normal_Kitchen_Lights.members.all?(&:on?)).to be true
      end

      it "turns the normal kitchen lights off with #{description} of the bottom paddle" do
        set_all(All_Kitchen_Lights, ON)
        Kitchen_Lights_Scene_2.update(click)

        expect(Normal_Kitchen_Lights.members.all?(&:off?)).to be true
      end
    end

    it "turns all the kitchen lights on with three clicks of the top paddle" do
      set_all(All_Kitchen_Lights, OFF)
      Kitchen_Lights_Scene_1.update(ZWave::Paddle::THREE_CLICKS)

      expect(All_Kitchen_Lights.members.all?(&:on?)).to be true
    end

    it "turns all the kitchen lights off with three clicks of the bottom paddle" do
      set_all(All_Kitchen_Lights, ON)
      Kitchen_Lights_Scene_2.update(ZWave::Paddle::THREE_CLICKS)

      expect(All_Kitchen_Lights.members.all?(&:off?)).to be true
    end
  end

  describe "resetting the basement" do
    # Two clicks of an accent paddle or four clicks of the bottom light paddle
    triggers = {
      "two clicks of the desk accent paddle" => -> { Kitchen_Accent_Desk_Scene_2.update(ZWave::Paddle::TWO_CLICKS) },
      "two clicks of the sink accent paddle" => -> { Kitchen_Accent_Sink_Scene_2.update(ZWave::Paddle::TWO_CLICKS) },
      "four clicks of the bottom light paddle" => -> { Kitchen_Lights_Scene_2.update(ZWave::Paddle::FOUR_CLICKS) }
    }

    triggers.each do |description, trigger|
      context "with #{description} and someone in the basement" do
        before do
          suspend_rules do
            Basement_Total_Occupancy.update(2)
            Basement_All_Lights.members.each { |light| light.update(ON) }
          end
          instance_exec(&trigger)
        end

        it "zeroes each Hiome basement room" do
          hiome_urls.each do |url|
            expect(OpenHAB::Core::Actions::HTTP).to have_received(:sendHttpPutRequest)
              .with(url, "application/json", %({"occupancy_count": 0}), HIOME_TIMEOUT_MS)
          end
        end

        it "turns the basement lights off" do
          expect(Basement_All_Lights.members.all?(&:off?)).to be true
        end
      end
    end

    context "with nobody in the basement" do
      before do
        suspend_rules do
          Basement_Total_Occupancy.update(0)
          Basement_All_Lights.members.each { |light| light.update(ON) }
        end
        Kitchen_Lights_Scene_2.update(ZWave::Paddle::FOUR_CLICKS)
      end

      it "does not touch Hiome" do
        expect(OpenHAB::Core::Actions::HTTP).not_to have_received(:sendHttpPutRequest)
      end

      it "leaves the basement lights on" do
        expect(Basement_All_Lights.members.all?(&:on?)).to be true
      end
    end

    context "when a Hiome request fails" do
      before do
        suspend_rules do
          Basement_Total_Occupancy.update(2)
          Basement_All_Lights.members.each { |light| light.update(ON) }
        end
        allow(OpenHAB::Core::Actions::HTTP).to receive(:sendHttpPutRequest).and_raise(IOError, "unreachable")
        Kitchen_Lights_Scene_2.update(ZWave::Paddle::FOUR_CLICKS)
      end

      it "still tries every room" do
        expect(OpenHAB::Core::Actions::HTTP).to have_received(:sendHttpPutRequest).exactly(hiome_urls.size).times
      end

      it "still turns the basement lights off" do
        expect(Basement_All_Lights.members.all?(&:off?)).to be true
      end
    end
  end
end
