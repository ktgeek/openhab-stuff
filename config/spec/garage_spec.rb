# frozen_string_literal: true

RSpec.describe "garage.rb" do
  let(:awtrix) { instance_double(Awtrix::ClockGroup, show_custom_notification: nil, set_indicator_color: nil) }

  before do
    allow(Awtrix).to receive(:all_clocks).and_return(awtrix)
    allow(TvNotification).to receive(:notify)
  end

  # What the rule does for each door state. A method because the libraries these constants live in aren't loaded until
  # the suite starts, which is after the examples below are defined.
  def expected_for(state)
    {
      "OPENING" => { target: ON, blink: ON, led: Homeseer::LedColor::RED, awtrix: Awtrix::Color::RED,
                     icon: "garagedooropen" },
      "OPEN" => { target: ON, blink: OFF, led: Homeseer::LedColor::RED, awtrix: Awtrix::Color::RED,
                  icon: "garageopened" },
      "CLOSING" => { target: OFF, blink: ON, led: Homeseer::LedColor::GREEN, awtrix: Awtrix::Color::GREEN,
                     icon: "garagedoorclose" },
      "CLOSED" => { target: OFF, blink: OFF, led: Homeseer::LedColor::GREEN, awtrix: nil, icon: "garageclosed" }
    }.fetch(state)
  end

  def garage_item(size, name)
    items["Garage_#{size}Door_#{name}"]
  end

  describe "door operation changes" do
    moving_states = %w[OPENING CLOSING]

    %w[Small Large].each do |size|
      context "when the #{size.downcase} door goes IDLE fully down" do
        before do
          garage_item(size, "Position").update(100)
          garage_item(size, "Current_Operation").update("IDLE")
        end

        it "reports the door as CLOSED" do
          expect(garage_item(size, "State").state.to_s).to eq("CLOSED")
        end

        it "turns the binary state off" do
          expect(garage_item(size, "State_Binary")).to be_off
        end
      end

      context "when the #{size.downcase} door goes IDLE part way up" do
        before do
          garage_item(size, "Position").update(50)
          garage_item(size, "Current_Operation").update("IDLE")
        end

        it "reports the door as OPEN" do
          expect(garage_item(size, "State").state.to_s).to eq("OPEN")
        end

        it "turns the binary state on" do
          expect(garage_item(size, "State_Binary")).to be_on
        end
      end

      moving_states.each do |state|
        it "reports the #{size.downcase} door as #{state} when its operation is IS_#{state}" do
          garage_item(size, "Current_Operation").update("IS_#{state}")

          expect(garage_item(size, "State").state.to_s).to eq(state)
        end
      end
    end
  end

  describe "door state changes" do
    %w[OPENING OPEN CLOSING CLOSED].each do |state|
      context "when the small door is #{state}" do
        let(:expected) { expected_for(state) }
        let(:message) { "Small Garage Door #{state.humanize}" }

        before do
          Garage_SmallDoor_Target_State.update(expected[:target] == ON ? OFF : ON)
          Garage_SmallDoor_State.update(state)
        end

        it "sets the target state" do
          expect(Garage_SmallDoor_Target_State.state).to eq(expected[:target])
        end

        it "lights the open LEDs" do
          expect(Garage_SmallDoor_Open_LEDs.members.map(&:state).uniq).to eq [expected[:led]]
        end

        it "sets the blinking LEDs" do
          expect(Garage_SmallDoor_Open_LEDs_Blink.members.map(&:state).uniq).to eq [expected[:blink]]
        end

        it "notifies the TVs, except one showing the Apple TV" do
          expect(TvNotification).to have_received(:notify).with(message:, avoid_appletv: true)
        end

        it "shows the notification on the clocks" do
          expect(awtrix).to have_received(:show_custom_notification).with(
            message:, icon: expected[:icon], color: expected[:awtrix]
          )
        end

        it "sets the clocks' indicator" do
          expect(awtrix).to have_received(:set_indicator_color).with(
            Awtrix::INDICATORS[Garage_SmallDoor], expected[:awtrix], blink: expected[:blink] == ON
          )
        end
      end
    end

    context "when the large door is OPENING" do
      before { Garage_LargeDoor_State.update("OPENING") }

      it "sets the large door's target state" do
        expect(Garage_LargeDoor_Target_State).to be_on
      end

      it "lights the large door's open LEDs" do
        expect(Garage_LargeDoor_Open_LEDs.members.map(&:state).uniq).to eq [Homeseer::LedColor::RED]
      end

      it "shows the notification on the clocks" do
        expect(awtrix).to have_received(:show_custom_notification).with(
          message: "Large Garage Door Opening", icon: "garagedooropen", color: Awtrix::Color::RED
        )
      end

      it "leaves the small door's target state alone" do
        expect(Garage_SmallDoor_Target_State).to be_null
      end
    end

    context "when the small door gets a state the rule doesn't know" do
      before do
        Garage_SmallDoor_Target_State.update(OFF)
        Garage_SmallDoor_State.update("SOME_UNKNOWN_STATE")
      end

      it "leaves the target state alone" do
        expect(Garage_SmallDoor_Target_State).to be_off
      end

      it "doesn't notify the clocks" do
        expect(awtrix).not_to have_received(:show_custom_notification)
      end
    end
  end

  describe "target state commands" do
    it "opens the small door when its target state is commanded on" do
      allow(Garage_SmallDoor_Position).to receive(:command)

      Garage_SmallDoor_Target_State.command(ON)

      expect(Garage_SmallDoor_Position).to have_received(:command).with(UP)
    end

    it "closes the small door when its target state is commanded off" do
      allow(Garage_SmallDoor_Position).to receive(:command)

      Garage_SmallDoor_Target_State.command(OFF)

      expect(Garage_SmallDoor_Position).to have_received(:command).with(DOWN)
    end

    it "opens the large door when its target state is commanded on" do
      allow(Garage_LargeDoor_Position).to receive(:command)

      Garage_LargeDoor_Target_State.command(ON)

      expect(Garage_LargeDoor_Position).to have_received(:command).with(UP)
    end

    it "closes the large door when its target state is commanded off" do
      allow(Garage_LargeDoor_Position).to receive(:command)

      Garage_LargeDoor_Target_State.command(OFF)

      expect(Garage_LargeDoor_Position).to have_received(:command).with(DOWN)
    end
  end
end
