# frozen_string_literal: true

# TvNotification is loaded by the rule files, after the items exist, so it is only referenced inside the examples
RSpec.describe "TvNotification" do
  let(:message) { "Someone is at the door" }

  def set_tvs(family_room:, basement:)
    suspend_rules do
      FamilyRoom_TV_Power.update(family_room)
      Basement_TV_Power.update(basement)
      FamilyRoom_Receiver_Input_Source.update(1)
      Basement_Receiver_Input_Source.update(1)
    end
  end

  describe ".notify" do
    it "sends the message to every TV that is on" do
      set_tvs(family_room: ON, basement: ON)
      TvNotification.notify(message:)

      expect([FamilyRoom_TV_Toast, Basement_TV_Toast].map { |toast| toast.state.to_s }).to eq [message, message]
    end

    it "leaves a TV that is off alone" do
      set_tvs(family_room: ON, basement: OFF)
      TvNotification.notify(message:)

      expect(Basement_TV_Toast.state).to be_nil
    end

    it "sends to the TV that is on when the other is off" do
      set_tvs(family_room: ON, basement: OFF)
      TvNotification.notify(message:)

      expect(FamilyRoom_TV_Toast.state.to_s).to eq message
    end

    it "sends nothing when every TV is off" do
      set_tvs(family_room: OFF, basement: OFF)
      TvNotification.notify(message:)

      expect([FamilyRoom_TV_Toast, Basement_TV_Toast].map(&:state)).to eq [nil, nil]
    end

    context "with only: a toast" do
      before do
        set_tvs(family_room: ON, basement: ON)
        TvNotification.notify(message:, only: Basement_TV_Toast)
      end

      it "sends to that TV" do
        expect(Basement_TV_Toast.state.to_s).to eq message
      end

      it "skips the other TV" do
        expect(FamilyRoom_TV_Toast.state).to be_nil
      end
    end

    context "with only: the toast of a TV that is off" do
      it "sends nothing" do
        set_tvs(family_room: ON, basement: OFF)
        TvNotification.notify(message:, only: Basement_TV_Toast)

        expect([FamilyRoom_TV_Toast, Basement_TV_Toast].map(&:state)).to eq [nil, nil]
      end
    end

    context "with avoid_appletv and the family room receiver on the Apple TV input" do
      before do
        set_tvs(family_room: ON, basement: ON)
        FamilyRoom_Receiver_Input_Source.update(17)
        TvNotification.notify(message:, avoid_appletv: true)
      end

      it "skips the TV on the Apple TV input" do
        expect(FamilyRoom_TV_Toast.state).to be_nil
      end

      it "still sends to the other TV" do
        expect(Basement_TV_Toast.state.to_s).to eq message
      end
    end

    context "with avoid_appletv and the receiver on another input" do
      it "sends to the TV" do
        set_tvs(family_room: ON, basement: OFF)
        FamilyRoom_Receiver_Input_Source.update(3)
        TvNotification.notify(message:, avoid_appletv: true)

        expect(FamilyRoom_TV_Toast.state.to_s).to eq message
      end
    end

    context "without avoid_appletv and the receiver on the Apple TV input" do
      it "sends to the TV" do
        set_tvs(family_room: ON, basement: OFF)
        FamilyRoom_Receiver_Input_Source.update(17)
        TvNotification.notify(message:)

        expect(FamilyRoom_TV_Toast.state.to_s).to eq message
      end
    end
  end
end
