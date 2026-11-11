# frozen_string_literal: true

RSpec.describe "lock_rules.rb" do
  let(:awtrix) { instance_double(Awtrix::ClockGroup, show_custom_notification: nil, set_indicator_color: nil) }

  before do
    allow(Awtrix).to receive(:all_clocks).and_return(awtrix)
    allow(Notification).to receive(:send)
    allow(TvNotification).to receive(:notify)
  end

  describe "Entrance_FrontDoor_Lock_Alarm_Type" do
    %w[KEYPAD_JAMMED REMOTE_JAMMED AUTO_JAMMED].each do |alarm|
      it "sets CurrentState to JAMMED on #{alarm}" do
        Entrance_FrontDoor_Lock_Alarm_Type.update(Kwikset::Alarm.const_get(alarm))

        expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::JAMMED
      end
    end
  end

  describe "Entrance_FrontDoor_Lock_Raw_Notification" do
    context "with a keypad unlock event" do
      let(:message) { "Front Door keypad unlocked by Keith" }

      before do
        # the harness doesn't start the transformation services, so the MAP lookup has to be faked
        allow(OpenHAB::Core::Actions::Transformation).to receive(:transform)
          .with("MAP", "lock_user.map", 1).and_return("Keith")
        Entrance_FrontDoor_Lock_Raw_Notification.update(%({"event":6,"type":6,"parameters":{"userId":1}}))
      end

      it "sends a notification with the mapped user's name" do
        expect(Notification).to have_received(:send).with(message)
      end

      it "notifies the TVs" do
        expect(TvNotification).to have_received(:notify).with(message:)
      end

      it "notifies the clocks" do
        expect(awtrix).to have_received(:show_custom_notification).with(message:, icon: "front_door_lock")
      end

      it "resets the item" do
        expect(Entrance_FrontDoor_Lock_Raw_Notification.state).to be_nil
      end
    end

    context "with any other event and type" do
      before { Entrance_FrontDoor_Lock_Raw_Notification.update(%({"event":1,"type":1})) }

      it "doesn't send a notification" do
        expect(Notification).not_to have_received(:send)
      end

      it "resets the item" do
        expect(Entrance_FrontDoor_Lock_Raw_Notification.state).to be_nil
      end
    end

    context "when the notification is blank" do
      before { Entrance_FrontDoor_Lock_Raw_Notification.update(NULL) }

      it "doesn't send a notification" do
        expect(Notification).not_to have_received(:send)
      end
    end
  end

  describe "Entrance_FrontDoor_Lock_Mode proxy" do
    context "when the mode is Secured" do
      before { Entrance_FrontDoor_Lock_Mode.update(ZWave::Lock::Mode::SECURED) }

      it "secures the target" do
        expect(Entrance_FrontDoor_Lock_Target).to be_on
      end

      it "sets the homekit state to secured" do
        expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::SECURED
      end
    end

    %w[UNSECURED UNSECURED_WITH_TIMEOUT INSIDE_UNSECURED INSIDE_UNSECURED_WITH_TIMEOUT OUTSIDE_UNSECURED
       OUTSIDE_UNSECURED_WITH_TIMEOUT].each do |mode|
      context "when the mode is #{mode}" do
        before do
          Entrance_FrontDoor_Lock_Target.update(ON)
          Entrance_FrontDoor_Lock_Mode.update(ZWave::Lock::Mode.const_get(mode))
        end

        it "unsecures the target" do
          expect(Entrance_FrontDoor_Lock_Target).to be_off
        end

        it "sets the homekit state to unsecured" do
          expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::UNSECURED
        end
      end
    end

    context "when the mode is unrecognized" do
      before do
        Entrance_FrontDoor_Lock_Target.update(ON)
        Entrance_FrontDoor_Lock_CurrentState.update(Homekit::LockStatus::SECURED)
        Entrance_FrontDoor_Lock_Mode.update(ZWave::Lock::Mode::UNKNOWN)
      end

      it "leaves the target alone" do
        expect(Entrance_FrontDoor_Lock_Target).to be_on
      end

      it "leaves the homekit state alone" do
        expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::SECURED
      end
    end
  end

  describe "Entrance_FrontDoor_Lock_Target proxy command" do
    it "commands the lock mode to Secured when locked" do
      Entrance_FrontDoor_Lock_Mode.update(ZWave::Lock::Mode::UNSECURED)
      allow(Entrance_FrontDoor_Lock_Mode).to receive(:command)

      Entrance_FrontDoor_Lock_Target.command(ON)

      expect(Entrance_FrontDoor_Lock_Mode).to have_received(:command).with(ZWave::Lock::Mode::SECURED)
    end

    it "commands the lock mode to Unsecured when unlocked" do
      Entrance_FrontDoor_Lock_Mode.update(ZWave::Lock::Mode::SECURED)
      allow(Entrance_FrontDoor_Lock_Mode).to receive(:command)

      Entrance_FrontDoor_Lock_Target.command(OFF)

      expect(Entrance_FrontDoor_Lock_Mode).to have_received(:command).with(ZWave::Lock::Mode::UNSECURED)
    end
  end

  describe "House_Perimeter_Contacts and lock status" do
    def perimeter_led_states
      House_Perimeter_LEDs.members.map(&:state).uniq
    end

    context "when a perimeter contact opens" do
      let(:message) { "House Perimeter Contacts is now Open" }

      before { Entrance_FrontDoor_Contact.update(OPEN) }

      it "lights the perimeter LEDs red" do
        expect(perimeter_led_states).to eq [Homeseer::LedColor::RED]
      end

      it "sets the clocks' indicator red" do
        expect(awtrix).to have_received(:set_indicator_color).with(
          Awtrix::INDICATORS[House_Perimeter_Contacts], Awtrix::Color::RED
        )
      end

      it "shows the notification on the clocks" do
        expect(awtrix).to have_received(:show_custom_notification).with(
          message:, icon: "door", color: Awtrix::Color::RED
        )
      end

      it "notifies the TVs, including one showing the Apple TV" do
        expect(TvNotification).to have_received(:notify).with(message:, avoid_appletv: false)
      end
    end

    context "when the perimeter contacts close while the front door is unlocked" do
      let(:message) { "House Perimeter Contacts is now Closed" }

      before do
        suspend_rules do
          Entrance_FrontDoor_Lock_Target.update(OFF)
          Entrance_FrontDoor_Contact.update(OPEN)
        end
        Entrance_FrontDoor_Contact.update(CLOSED)
      end

      it "lights the perimeter LEDs yellow" do
        expect(perimeter_led_states).to eq [Homeseer::LedColor::YELLOW]
      end

      it "sets the clocks' indicator yellow" do
        expect(awtrix).to have_received(:set_indicator_color).with(
          Awtrix::INDICATORS[House_Perimeter_Contacts], Awtrix::Color::YELLOW
        )
      end

      it "shows the notification on the clocks" do
        expect(awtrix).to have_received(:show_custom_notification).with(
          message:, icon: "door", color: Awtrix::Color::YELLOW
        )
      end

      it "notifies the TVs, including one showing the Apple TV" do
        expect(TvNotification).to have_received(:notify).with(message:, avoid_appletv: false)
      end
    end

    context "when the front door locks with the perimeter contacts closed" do
      let(:message) { "Front Door Lock is now Locked" }

      before do
        suspend_rules do
          Entrance_FrontDoor_Contact.update(CLOSED)
          Entrance_FrontDoor_Lock_Target.update(OFF)
        end
        Entrance_FrontDoor_Lock_Target.update(ON)
      end

      it "turns the perimeter LEDs off" do
        expect(perimeter_led_states).to eq [Homeseer::LedColor::OFF]
      end

      it "clears the clocks' indicator" do
        expect(awtrix).to have_received(:set_indicator_color).with(Awtrix::INDICATORS[House_Perimeter_Contacts], nil)
      end

      it "shows the notification on the clocks without a color" do
        expect(awtrix).to have_received(:show_custom_notification).with(message:, icon: "door", color: nil)
      end

      it "notifies the TVs, except one showing the Apple TV" do
        expect(TvNotification).to have_received(:notify).with(message:, avoid_appletv: true)
      end
    end

    context "when the front door unlocks with the perimeter contacts closed" do
      let(:message) { "Front Door Lock is now Unlocked" }

      before do
        suspend_rules do
          Entrance_FrontDoor_Contact.update(CLOSED)
          Entrance_FrontDoor_Lock_Target.update(ON)
        end
        Entrance_FrontDoor_Lock_Target.update(OFF)
      end

      it "lights the perimeter LEDs yellow" do
        expect(perimeter_led_states).to eq [Homeseer::LedColor::YELLOW]
      end

      it "shows the notification on the clocks in yellow" do
        expect(awtrix).to have_received(:show_custom_notification).with(
          message:, icon: "door", color: Awtrix::Color::YELLOW
        )
      end

      it "notifies the TVs, except one showing the Apple TV" do
        expect(TvNotification).to have_received(:notify).with(message:, avoid_appletv: true)
      end
    end
  end
end
