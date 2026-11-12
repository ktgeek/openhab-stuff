# frozen_string_literal: true

# Awtrix refers to items when it loads, so it only exists once the rule files have loaded it and it can't be named here
RSpec.describe "Awtrix::ClockGroup" do
  subject(:group) { Awtrix::ClockGroup.new(clocks) }

  let(:clocks) { Array.new(2) { instance_double(AwtrixNg).as_null_object } }

  describe "#show_custom_notification" do
    before { group.show_custom_notification(message: "Door open", icon: "door", color: [255, 0, 0]) }

    it "forwards the notification to every clock" do
      expect(clocks).to all(have_received(:show_custom_notification)
        .with(message: "Door open", icon: "door", color: [255, 0, 0]))
    end
  end

  describe "#set_indicator_color" do
    before { group.set_indicator_color(1, [0, 255, 0], blink: true) }

    it "forwards the indicator color to every clock" do
      expect(clocks).to all(have_received(:set_indicator_color).with(1, [0, 255, 0], blink: true))
    end
  end
end
