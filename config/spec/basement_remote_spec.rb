# frozen_string_literal: true

RSpec.describe "basement_remote.rb" do
  describe "Nanomote Quad" do
    it "turns on the Basement Normal Mode switch when the first button is pressed" do
      NanomoteQuad_Scene.update(1.0)

      expect(Basement_Normal_Mode_Switch).to be_on
    end

    it "turns the Basement Stairs Switch on if its off when the second button is pressed" do
      Basement_Stairs_Switch.off
      NanomoteQuad_Scene.update(2.0)

      expect(Basement_Stairs_Switch).to be_on
    end

    it "turns the Basement Stairs Switch off if its on when the second button is pressed" do
      Basement_Stairs_Switch.on
      NanomoteQuad_Scene.update(2.0)

      expect(Basement_Stairs_Switch).to be_off
    end

    it "sets the theater lights to full if the theater lights are less when button 3 is pressed" do
      Basement_Room_Theater_Lights.update(50)
      Basement_Room_Bar_Lights.update(100)

      expect { NanomoteQuad_Scene.update(3.0) }
        .to change { Basement_Room_Theater_Lights.state }.to(100)
    end

    it "sets bar lights to full if the bar lights are less when button 3 is pressed" do
      Basement_Room_Theater_Lights.update(100)
      Basement_Room_Bar_Lights.update(50)

      expect { NanomoteQuad_Scene.update(3.0) }
        .to change { Basement_Room_Bar_Lights.state }.to(100)
    end

    it "turns off the theater and bar lights if both are full when button 3 is pressed" do
      Basement_Room_Theater_Lights.update(100)
      Basement_Room_Bar_Lights.update(100)

      expect { NanomoteQuad_Scene.update(3.0) }
        .to change { Basement_Room_Bar_Lights.state }.to(0)
        .and change { Basement_Room_Theater_Lights.state }.to(0)
    end

    it "turns the theater and bar lights to full if both are less when button 3 is pressed" do
      Basement_Room_Theater_Lights.update(50)
      Basement_Room_Bar_Lights.update(50)

      expect { NanomoteQuad_Scene.update(3.0) }
        .to change { Basement_Room_Bar_Lights.state }.to(100)
        .and change { Basement_Room_Theater_Lights.state }.to(100)
    end

    it "turns on the Basement Movie Mode Switch when button 4 is pressed" do
      NanomoteQuad_Scene.update(4.0)

      expect(Basement_Movie_Mode_Switch).to be_on
    end
  end

  describe "basement scenes" do
    it "turn on Basement Normal Mode if a basement scene member gets a two click paddle up" do
      C_Basement_Scene.members.first.update(Homeseer::PADDLE_UP_TWO_CLICKS)

      expect(Basement_Normal_Mode_Switch).to be_on
    end

    it "turn on Basement Movie Mode if a basement scene member gets a two click paddle down" do
      C_Basement_Scene.members.first.update(Homeseer::PADDLE_DOWN_TWO_CLICKS)

      expect(Basement_Movie_Mode_Switch).to be_on
    end
  end
end
