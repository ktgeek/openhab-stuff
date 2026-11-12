# frozen_string_literal: true

RSpec.describe "scenes.rb" do
  it "resets a scene item to NULL once it changes to a value" do
    Kitchen_Lights_Scene_1.update(3)

    expect(Kitchen_Lights_Scene_1.state).to be_nil
  end

  it "resets scene items on other rooms too" do
    ExerciseRoom_DimmerLights_Scene_1.update(4)

    expect(ExerciseRoom_DimmerLights_Scene_1.state).to be_nil
  end
end
