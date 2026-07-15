# frozen_string_literal: true

RSpec.describe "garage.rb" do
  let(:awtrix) { instance_double(Awtrix3, show_custom_notification: nil, set_indicator_color: nil) }

  before { allow(Awtrix3).to receive(:office_clock).and_return(awtrix) }

  describe "door state changes" do
    it "opens the target state, lights LEDs red, and notifies while the small door is opening" do
      Garage_SmallDoor_State.update("OPENING")

      expect(Garage_SmallDoor_Target_State).to be_on
      expect(Garage_SmallDoor_Open_LEDs.members.map(&:state).uniq).to eq [Homeseer::LedColor::RED]
      expect(Garage_SmallDoor_Open_LEDs_Blink.members.all?(&:on?)).to be true
      expect(awtrix).to have_received(:show_custom_notification).with(
        message: "Small Garage Door Opening", icon: "garagedooropen", color: Awtrix3::Color::RED
      )
    end

    it "stops blinking once the small door is fully open" do
      Garage_SmallDoor_State.update("OPEN")

      expect(Garage_SmallDoor_Target_State).to be_on
      expect(Garage_SmallDoor_Open_LEDs_Blink.members.all?(&:off?)).to be true
    end

    it "closes the target state, lights LEDs green, and clears the awtrix indicator when fully closed" do
      Garage_SmallDoor_Target_State.update(ON)
      Garage_SmallDoor_State.update("CLOSED")

      expect(Garage_SmallDoor_Target_State).to be_off
      expect(Garage_SmallDoor_Open_LEDs.members.map(&:state).uniq).to eq [Homeseer::LedColor::GREEN]
      expect(awtrix).to have_received(:set_indicator_color).with(
        Awtrix3::INDICATORS[Garage_SmallDoor], nil, blink: false
      )
    end

    it "updates the large door's own target state and LEDs independently of the small door" do
      Garage_LargeDoor_State.update("OPENING")

      expect(Garage_LargeDoor_Target_State).to be_on
      expect(Garage_LargeDoor_Open_LEDs.members.map(&:state).uniq).to eq [Homeseer::LedColor::RED]
      expect(awtrix).to have_received(:show_custom_notification).with(
        message: "Large Garage Door Opening", icon: "garagedooropen", color: Awtrix3::Color::RED
      )
    end

    it "ignores an unrecognized door state" do
      Garage_SmallDoor_Target_State.update(OFF)
      Garage_SmallDoor_State.update("SOME_UNKNOWN_STATE")

      expect(Garage_SmallDoor_Target_State).to be_off
      expect(awtrix).not_to have_received(:show_custom_notification)
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

    it "closes the large door when its target state is commanded off" do
      allow(Garage_LargeDoor_Position).to receive(:command)

      Garage_LargeDoor_Target_State.command(OFF)

      expect(Garage_LargeDoor_Position).to have_received(:command).with(DOWN)
    end
  end
end
