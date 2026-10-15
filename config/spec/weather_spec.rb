# frozen_string_literal: true

require "weather"

RSpec.describe Weather do
  describe ".overlay_for" do
    {
      ":L:T" => "thunder",
      "S:H:T" => "thunder",
      "::A" => "storm",
      "::R" => "rain",
      ":H:RW" => "storm",
      ":VH:ZR" => "storm",
      ":L:R" => "drizzle",
      "::L" => "drizzle",
      "::ZL" => "drizzle",
      "::S" => "snow",
      ":H:SW" => "snow",
      "::WM" => "snow",
      "::IP" => "snow"
    }.each do |coded, overlay|
      it "maps #{coded.inspect} to #{overlay}" do
        expect(described_class.overlay_for(coded:, temp_f: 50)).to eq(overlay)
      end
    end

    it "shows frost when the sky is clear and it is freezing" do
      expect(described_class.overlay_for(coded: "", temp_f: 32)).to eq("frost")
    end

    it "shows frost when only fog is reported and it is freezing" do
      expect(described_class.overlay_for(coded: "::F", temp_f: 20)).to eq("frost")
    end

    it "shows nothing when the sky is clear and it is above freezing" do
      expect(described_class.overlay_for(coded: "", temp_f: 33)).to be_nil
    end

    it "shows nothing when the temperature is unknown" do
      expect(described_class.overlay_for(coded: "", temp_f: nil)).to be_nil
    end

    it "prefers precipitation over frost" do
      expect(described_class.overlay_for(coded: "::S", temp_f: 20)).to eq("snow")
    end

    it "shows nothing for an unrecognized code, even when freezing" do
      expect(described_class.overlay_for(coded: "::XYZ", temp_f: 20)).to be_nil
    end

    it "shows nothing, even when freezing, when the lookup failed" do
      expect(described_class.overlay_for(coded: nil, temp_f: 20)).to be_nil
    end
  end

  describe ".current_conditions" do
    before do
      allow(described_class).to receive_messages(secret: "secret-value", post_to_service_frd: body)
    end

    context "with a successful observation" do
      let(:body) { { success: true, response: { ob: { weatherPrimaryCoded: ":L:R" } } }.to_json }

      it "returns the coded weather" do
        expect(described_class.current_conditions).to eq(":L:R")
      end
    end

    context "with a clear-sky observation" do
      let(:body) { { success: true, response: { ob: { weatherPrimaryCoded: nil } } }.to_json }

      it "returns an empty string" do
        expect(described_class.current_conditions).to eq("")
      end
    end

    context "when the request failed" do
      let(:body) { nil }

      it "returns nil" do
        expect(described_class.current_conditions).to be_nil
      end
    end

    context "when Xweather reports an error" do
      let(:body) { { success: false, error: { code: "invalid_client" } }.to_json }

      it "returns nil" do
        expect(described_class.current_conditions).to be_nil
      end
    end

    context "when the response has no observation" do
      let(:body) { { success: true, response: {} }.to_json }

      it "returns nil" do
        expect(described_class.current_conditions).to be_nil
      end
    end

    context "when the response is not JSON" do
      let(:body) { "<html>bad gateway</html>" }

      it "returns nil" do
        expect(described_class.current_conditions).to be_nil
      end
    end
  end
end
