# frozen_string_literal: true

RSpec.describe "lock_rules.rb" do
  let(:awtrix) { instance_double(Awtrix3, show_custom_notification: nil, set_indicator_color: nil) }

  before { allow(Awtrix3).to receive(:office_clock).and_return(awtrix) }

  describe "Entrance_FrontDoor_Lock_Alarm_Type" do
    it "sets CurrentState to JAMMED when the keypad jams" do
      Entrance_FrontDoor_Lock_Alarm_Type.update(Kwikset::Alarm::KEYPAD_JAMMED)

      expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::JAMMED
    end

    it "sets CurrentState to JAMMED when the remote or auto-lock jams" do
      Entrance_FrontDoor_Lock_Alarm_Type.update(Kwikset::Alarm::REMOTE_JAMMED)
      expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::JAMMED

      Entrance_FrontDoor_Lock_Alarm_Type.update(Kwikset::Alarm::AUTO_JAMMED)
      expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::JAMMED
    end

    it "does not update CurrentState for a non-jam alarm type" do
      Entrance_FrontDoor_Lock_CurrentState.update(Homekit::LockStatus::SECURED)
      Entrance_FrontDoor_Lock_Alarm_Type.update(Kwikset::Alarm::KEYPAD_LOCK)

      expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::SECURED
    end
  end

  describe "Entrance_FrontDoor_Lock_Raw_Notification" do
    it "notifies with the mapped user's name on a keypad unlock event and resets the item" do
      Entrance_FrontDoor_Lock_Raw_Notification.update(%({"event":6,"type":6,"parameters":{"userId":1}}))

      expect(awtrix).to have_received(:show_custom_notification).with(
        message: "Front Door keypad unlocked by Keith", icon: "front_door_lock"
      )
      expect(Entrance_FrontDoor_Lock_Raw_Notification.state).to be_nil
    end

    it "does not notify for an unrelated event/type combination, but still resets the item" do
      Entrance_FrontDoor_Lock_Raw_Notification.update(%({"event":1,"type":1}))

      expect(awtrix).not_to have_received(:show_custom_notification)
      expect(Entrance_FrontDoor_Lock_Raw_Notification.state).to be_nil
    end

    it "resets the item without raising when the notification is blank" do
      expect { Entrance_FrontDoor_Lock_Raw_Notification.update(NULL) }.not_to raise_error
    end
  end

  describe "Entrance_FrontDoor_Lock_Mode proxy" do
    it "secures the target and homekit state when the mode is Secured" do
      Entrance_FrontDoor_Lock_Mode.update(ZWave::Lock::Mode::SECURED)

      expect(Entrance_FrontDoor_Lock_Target).to be_on
      expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::SECURED
    end

    it "unsecures the target and homekit state for any mode in the unsecured group" do
      Entrance_FrontDoor_Lock_Mode.update(ZWave::Lock::Mode::OUTSIDE_UNSECURED)

      expect(Entrance_FrontDoor_Lock_Target).to be_off
      expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::UNSECURED
    end

    it "leaves the target and homekit state alone for an unrecognized mode value" do
      Entrance_FrontDoor_Lock_Target.update(ON)
      Entrance_FrontDoor_Lock_CurrentState.update(Homekit::LockStatus::SECURED)

      Entrance_FrontDoor_Lock_Mode.update(ZWave::Lock::Mode::UNKNOWN)

      expect(Entrance_FrontDoor_Lock_Target).to be_on
      expect(Entrance_FrontDoor_Lock_CurrentState.state).to eq Homekit::LockStatus::SECURED
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

  describe "House_Perimeter_Contacts / lock status LEDs and notifications" do
    it "lights the perimeter LEDs red when a perimeter contact opens" do
      House_Perimeter_Contacts.update(ON)

      expect(awtrix).to have_received(:set_indicator_color).with(
        Awtrix3::INDICATORS[House_Perimeter_Contacts], Awtrix3::Color::RED
      )
    end

    it "lights the perimeter LEDs yellow when contacts are closed but the door is unlocked" do
      Entrance_FrontDoor_Lock_Target.update(OFF)
      House_Perimeter_Contacts.update(OFF)

      expect(awtrix).to have_received(:set_indicator_color).with(
        Awtrix3::INDICATORS[House_Perimeter_Contacts], Awtrix3::Color::YELLOW
      )
    end

    it "sends a door-status notification with no LED color when the door locks with contacts already closed" do
      House_Perimeter_Contacts.update(OFF)
      Entrance_FrontDoor_Lock_Target.update(ON)

      expect(awtrix).to have_received(:show_custom_notification).with(
        message: "Front Door Lock is now Locked", icon: "door", color: nil
      )
    end
  end
end
