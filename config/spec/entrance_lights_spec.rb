# frozen_string_literal: true

RSpec.describe "entrance_lights.rb" do
  describe "Hall Lights" do
    it "turns on all members of hall lights on when one is sent ON" do
      All_Hall_Lights.members.first.update(ON)

      expect(All_Hall_Lights.members.all?(&:on?)).to be true
    end

    it "turns on all members of hall lights off when one is sent OFF" do
      All_Hall_Lights.members.first.update(OFF)

      expect(All_Hall_Lights.members.all?(&:off?)).to be true
    end
  end

  describe "luminance based rules" do
    context "during a weekday" do
      context "between 9am and 10:30pm" do
        before { Timecop.freeze(Time.local(2023, 7, 10, 10, 0, 0)) }

        it "turns on the front yard lights when it is dark" do
          Entrance_Luminance.update(150)

          expect(Front_Yard_Lights.members.all?(&:on?)).to be true
        end

        it "turns off the front yard lights when it is light" do
          Entrance_Luminance.update(200)

          expect(Front_Yard_Lights.members.all?(&:off?)).to be true
        end

        it "turns on the hall lights when it is dark" do
          Entrance_Luminance.update(150)

          expect(All_Hall_Lights.members.all?(&:on?)).to be true
        end

        it "turns off the hall lights when it is light" do
          Entrance_Luminance.update(200)

          expect(All_Hall_Lights.members.all?(&:off?)).to be true
        end
      end

      context "between 5:50am and 9am" do
        before { Timecop.freeze(Time.local(2023, 7, 10, 6, 0, 0)) }

        it "turns on the front yard lights when it is dark" do
          Entrance_Luminance.update(150)

          expect(Front_Yard_Lights.members.all?(&:on?)).to be true
        end

        it "turns off the front yard lights when it is light" do
          Entrance_Luminance.update(200)

          expect(Front_Yard_Lights.members.all?(&:off?)).to be true
        end

        it "does not turn on the hall lights when it is light" do
          Entrance_Luminance.update(200)

          expect(All_Hall_Lights.members.all?(&:off?)).to be true
        end
      end
    end

    context "outside of 5:50am to 10:30pm" do
      before do
        Timecop.freeze(Time.local(2023, 7, 10, 1, 0, 0))
        Front_Yard_Lights.members.ensure.off
        All_Hall_Lights.members.ensure.off
      end

      it "does not turn on the front yard lights" do
        Entrance_Luminance.update(200)

        expect(Front_Yard_Lights.members.all?(&:off?)).to be true
      end

      it "does not turn on the hall lights" do
        Entrance_Luminance.update(200)

        expect(All_Hall_Lights.members.all?(&:off?)).to be true
      end
    end

    context "during the weekend" do
      context "between 5:50am and 9am" do
        before do
          Timecop.freeze(Time.local(2023, 7, 8, 6, 0, 0))
          Front_Yard_Lights.members.ensure.off
          All_Hall_Lights.members.ensure.off
        end

        it "does not turn on the front yard lights" do
          Entrance_Luminance.update(200)

          expect(Front_Yard_Lights.members.all?(&:off?)).to be true
        end

        it "does not turn on the hall lights" do
          Entrance_Luminance.update(200)

          expect(All_Hall_Lights.members.all?(&:off?)).to be true
        end
      end
    end
  end
end
