# frozen_string_literal: true

require "awtrix_ng"

RSpec.describe AwtrixNg do
  subject(:clock) { described_class.new(instance_double(OpenHAB::Core::Things::Thing)) }

  # The actions come from the binding's thing handler, which isn't installed here, so there is no class to verify
  let(:actions) { spy("awtrixlight actions") } # rubocop:disable RSpec/VerifiedDoubles
  let(:red) { [255, 0, 0] }

  before { allow(described_class).to receive(:actions).and_return(actions) }

  # The binding takes the colors as Java int arrays
  def color_matching(rgb)
    satisfy { |color| color.to_a == rgb }
  end

  describe "#show_custom_notification" do
    let(:default_params) do
      { "text" => "Door open", "icon" => "door", "wakeup" => true, "stack" => true, "textCase" => "asTyped" }
    end

    it "sends the message and icon with the default settings" do
      clock.show_custom_notification(message: "Door open", icon: "door")

      expect(actions).to have_received(:show_custom_notification).with(default_params)
    end

    it "drops the text case when the message is case insensitive" do
      clock.show_custom_notification(message: "Door open", icon: "door", case_insensitive: true)

      expect(actions).to have_received(:show_custom_notification).with(default_params.except("textCase"))
    end

    it "adds the text color when one is given" do
      clock.show_custom_notification(message: "Door open", icon: "door", color: red)

      expect(actions).to have_received(:show_custom_notification)
        .with(hash_including("textColor" => color_matching(red)))
    end

    it "adds the name when one is given" do
      clock.show_custom_notification(message: "Door open", icon: "door", name: "garage")

      expect(actions).to have_received(:show_custom_notification).with(hash_including("name" => "garage"))
    end
  end

  describe "#set_indicator_color" do
    it "activates the indicator with the color" do
      clock.set_indicator_color(2, red)

      expect(actions).to have_received(:activate_indicator).with(2, color_matching(red))
    end

    it "blinks the indicator every 500ms when asked to blink" do
      clock.set_indicator_color(2, red, blink: true)

      expect(actions).to have_received(:blink_indicator).with(2, color_matching(red), 500)
    end

    it "deactivates the indicator when there is no color" do
      clock.set_indicator_color(2, nil)

      expect(actions).to have_received(:deactivate_indicator).with(2)
    end
  end
end
