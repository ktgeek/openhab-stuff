# frozen_string_literal: true

RSpec.describe "basement_remote.rb" do
  describe "Nanomote Quad" do
    it "turns on the Basement Normal Mode switch when the first button is pressed" do
      Basement_NanomoteQuad_Scene_1.update(ZWave::Paddle::CLICK)

      expect(Basement_Normal_Switch).to be_on
    end

    it "turns the Basement Stairs Switch on if its off when the second button is pressed" do
      Basement_Stairs_Switch.off
      Basement_NanomoteQuad_Scene_2.update(ZWave::Paddle::CLICK)

      expect(Basement_Stairs_Switch).to be_on
    end

    it "turns the Basement Stairs Switch off if its on when the second button is pressed" do
      Basement_Stairs_Switch.on
      Basement_NanomoteQuad_Scene_2.update(ZWave::Paddle::CLICK)

      expect(Basement_Stairs_Switch).to be_off
    end

    it "sets the theater lights to full if the theater lights are less when button 3 is pressed" do
      Basement_TheaterLights.update(50)
      Basement_BarLights.update(100)

      expect { Basement_NanomoteQuad_Scene_3.update(ZWave::Paddle::CLICK) }
        .to change(Basement_TheaterLights, :state).to(100)
    end

    it "sets bar lights to full if the bar lights are less when button 3 is pressed" do
      Basement_TheaterLights.update(100)
      Basement_BarLights.update(50)

      expect { Basement_NanomoteQuad_Scene_3.update(ZWave::Paddle::CLICK) }
        .to change(Basement_BarLights, :state).to(100)
    end

    it "turns off the theater and bar lights if both are full when button 3 is pressed" do
      Basement_TheaterLights.update(100)
      Basement_BarLights.update(100)

      expect { Basement_NanomoteQuad_Scene_3.update(ZWave::Paddle::CLICK) }
        .to change(Basement_BarLights, :state).to(0)
        .and change(Basement_TheaterLights, :state).to(0)
    end

    it "turns the theater and bar lights to full if both are less when button 3 is pressed" do
      Basement_TheaterLights.update(50)
      Basement_BarLights.update(50)

      expect { Basement_NanomoteQuad_Scene_3.update(ZWave::Paddle::CLICK) }
        .to change(Basement_BarLights, :state).to(100)
        .and change(Basement_TheaterLights, :state).to(100)
    end

    it "turns on the Basement Movie Mode Switch when button 4 is pressed" do
      Basement_NanomoteQuad_Scene_4.update(ZWave::Paddle::CLICK)

      expect(Basement_Movie_Switch).to be_on
    end
  end

  describe "basement scenes" do
    it "turn on Basement Normal Mode if a Basement_Scenes_1 member gets a two click paddle press" do
      Basement_Scenes_1.members.first.update(ZWave::Paddle::TWO_CLICKS)

      expect(Basement_Normal_Switch).to be_on
    end

    it "turn on Basement Movie Mode if a Basement_Scenes_2 member gets a two click paddle press" do
      Basement_Scenes_2.members.first.update(ZWave::Paddle::TWO_CLICKS)

      expect(Basement_Movie_Switch).to be_on
    end
  end
end
