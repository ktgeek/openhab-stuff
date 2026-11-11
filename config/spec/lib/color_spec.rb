# frozen_string_literal: true

require "color"

RSpec.describe Color do
  describe ".for_temperature" do
    # The color is snapped to 8-bit RGB, which moves the hue by up to about a tenth of a degree.
    let(:hue_tolerance) { 0.12 }

    def hue_for(temp)
      described_class.for_temperature(temp).hue.to_f
    end

    it "is deep blue (245) at -10" do
      expect(hue_for(-10)).to be_within(hue_tolerance).of(245)
    end

    it "stays deep blue below -10" do
      expect(hue_for(-25)).to eq(hue_for(-10))
    end

    it "is cyan-blue (185) at freezing" do
      expect(hue_for(32)).to be_within(hue_tolerance).of(185)
    end

    it "is red at 100" do
      expect(hue_for(100)).to eq(0)
    end

    it "stays red above 100" do
      expect(hue_for(115)).to eq(0)
    end

    it "is halfway between blue and cyan-blue below freezing" do
      expect(hue_for(11)).to be_within(hue_tolerance).of(215)
    end

    it "is halfway between cyan-blue and red above freezing" do
      expect(hue_for(66)).to be_within(hue_tolerance).of(92.5)
    end

    it "accepts the temperature as a string" do
      expect(described_class.for_temperature("55.5")).to eq(described_class.for_temperature(55.5))
    end

    it "moves from blue towards red as it gets warmer" do
      hues = (-10..100).step(10).map { |temp| hue_for(temp) }

      expect(hues).to eq(hues.sort.reverse)
    end

    it "is fully saturated and bright" do
      color = described_class.for_temperature(55)

      expect([color.saturation.to_f, color.brightness.to_f]).to eq([100, 100])
    end

    it "survives the clocks' hex round trip unchanged" do
      color = described_class.for_temperature(55)

      expect(OpenHAB::Core::Types::HSBType.new(color.to_hex)).to eq(color)
    end
  end
end
