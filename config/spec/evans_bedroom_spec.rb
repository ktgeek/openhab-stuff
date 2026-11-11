# frozen_string_literal: true

require "color"

RSpec.describe "evans_bedroom.rb" do
  let(:button) { "homeassistant:device:26bcbec1ee:zigbee2mqtt_5F0x282c02bfffee018b" }

  describe "LED button single tap" do
    it "turns the LEDs on when they are off" do
      EvansRoom_LED_Color.update(HSBType.new(0, 0, 0))
      trigger_channel("#{button}:single", "single")

      expect(EvansRoom_LED_Color).to be_on
    end

    it "turns the LEDs off when they are on" do
      EvansRoom_LED_Color.update(Color::RED)
      trigger_channel("#{button}:single", "single")

      expect(EvansRoom_LED_Color).to be_off
    end
  end
end
