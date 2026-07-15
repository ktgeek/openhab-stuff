# frozen_string_literal: true

RSpec.describe "laundry_room.rb" do
  describe "Side Yard Light" do
    it "turns off when the laundry room door is closed" do
      LaundryRoom_Door_Contact.update(CLOSED)

      expect(SideYard_Light_Color).to be_off
    end

    it "turns on when the laundry room door is opened and the sun is down" do
      Sun_Status.update(SunStatus::DOWN)
      LaundryRoom_Door_Contact.update(OPEN)

      expect(SideYard_Light_Color).to be_on
    end

    it "does nothing when the laundry room door is opened and the sun is up" do
      Sun_Status.update(SunStatus::UP)
      LaundryRoom_Door_Contact.update(OPEN)

      expect(SideYard_Light_Color.state).to be_off.or be_nil
    end
  end
end
