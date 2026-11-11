# frozen_string_literal: true

RSpec.describe "laundry_room.rb" do
  describe "Side Yard Light and the laundry room door" do
    it "turns off when the laundry room door is closed" do
      SideYard_Light_Color.update(ON)
      LaundryRoom_Door_Contact.update(CLOSED)

      expect(SideYard_Light_Color).to be_off
    end

    it "turns on when the laundry room door is opened and the sun is down" do
      Sun_Status.update(SunStatus::DOWN)
      LaundryRoom_Door_Contact.update(OPEN)

      expect(SideYard_Light_Color).to be_on
    end

    it "stays off when the laundry room door is opened and the sun is up" do
      Sun_Status.update(SunStatus::UP)
      LaundryRoom_Door_Contact.update(OPEN)

      expect(SideYard_Light_Color).not_to be_on
    end
  end

  describe "Side Yard Light and the side yard scene switch" do
    it "turns on when scene 1 is clicked" do
      SideYard_Light_Color.update(OFF)
      SideYard_Lights_Scene_1.update(ZWave::Paddle::CLICK)

      expect(SideYard_Light_Color).to be_on
    end

    it "turns off when scene 2 is clicked" do
      SideYard_Light_Color.update(ON)
      SideYard_Lights_Scene_2.update(ZWave::Paddle::CLICK)

      expect(SideYard_Light_Color).to be_off
    end
  end
end
