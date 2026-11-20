# frozen_string_literal: true

# Announce is loaded by the rule files, after the items exist, so it is only referenced inside the examples
RSpec.describe "Announce" do
  let(:awtrix) { instance_double(Awtrix::ClockGroup, show_custom_notification: nil) }

  before do
    allow(Awtrix).to receive(:all_clocks).and_return(awtrix)
    allow(TvNotification).to receive(:notify)
  end

  describe ".show" do
    it "notifies the TVs" do
      Announce.show(message: "Hello", icon: "door")

      expect(TvNotification).to have_received(:notify).with(message: "Hello", avoid_appletv: false)
    end

    it "passes avoid_appletv on to the TVs" do
      Announce.show(message: "Hello", icon: "door", avoid_appletv: true)

      expect(TvNotification).to have_received(:notify).with(message: "Hello", avoid_appletv: true)
    end

    it "shows the message, icon and color on the clocks" do
      Announce.show(message: "Hello", icon: "door", color: Awtrix::Color::RED)

      expect(awtrix).to have_received(:show_custom_notification)
        .with(message: "Hello", icon: "door", color: Awtrix::Color::RED)
    end

    it "leaves the color unset by default" do
      Announce.show(message: "Hello", icon: "door")

      expect(awtrix).to have_received(:show_custom_notification).with(message: "Hello", icon: "door", color: nil)
    end
  end
end
