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

  describe ".feels_like" do
    # Expected values come from the NWS wind chill and heat index formulas and agree with the NWS tables
    {
      "the temperature when it is mild" => [{ temp: 60, humidity: 50, wind_speed: 10 }, 60.0],
      "the temperature when it is cold with under 3 mph of wind" => [{ temp: 40, humidity: 50, wind_speed: 2 }, 40.0],
      "the wind chill when it is 50 or below with 3 mph of wind or more" =>
        [{ temp: 40, humidity: 50, wind_speed: 10 }, 33.6],
      "the wind chill at the lowest valid wind speed" => [{ temp: 50, humidity: 50, wind_speed: 3 }, 49.7],
      "the simple heat index when it works out below 80" => [{ temp: 80, humidity: 40, wind_speed: 0 }, 79.8],
      "the full heat index when it works out at 80 or above" => [{ temp: 96, humidity: 65, wind_speed: 0 }, 121.0],
      "the full heat index on a hot, humid day, ignoring the wind" =>
        [{ temp: 90, humidity: 70, wind_speed: 5 }, 105.9]
    }.each do |description, (conditions, feels_like)|
      it "is #{description}" do
        expect(described_class.feels_like(**conditions)).to eq(feels_like)
      end
    end

    it "accepts strings, as the items provide them" do
      expect(described_class.feels_like(temp: "40", humidity: "50", wind_speed: "10")).to eq(33.6)
    end
  end

  describe ".dew_point" do
    it "is about 57F at 77F and 50% humidity" do
      expect(described_class.dew_point(temp: 77, humidity: 50)).to eq(56.9)
    end

    it "is the temperature at 100% humidity" do
      expect(described_class.dew_point(temp: 68, humidity: 100)).to eq(68.0)
    end
  end

  describe ".post_to_weather_services" do
    let(:pws_url) { "https://www.pwsweather.com/pwsupdate/pwsupdate.php" }
    let(:wunderground_url) { "https://weatherstation.wunderground.com/weatherstation/updateweatherstation.php" }

    before do
      allow(described_class).to receive(:secret) { |key| "#{key}-value" }
      allow(described_class).to receive(:post_to_service_frd).and_return("success")
      described_class.post_to_weather_services({ tempf: 50 })
    end

    it "posts the readings and credentials to PWSWeather" do
      expect(described_class).to have_received(:post_to_service_frd)
        .with(url: pws_url, params: { tempf: 50, ID: "station_id-value", PASSWORD: "pws_key-value" })
    end

    it "posts the readings, the update action and credentials to Weather Underground" do
      expect(described_class).to have_received(:post_to_service_frd).with(
        url: wunderground_url,
        params: { tempf: 50, ID: "station_id-value", action: "updateraw", PASSWORD: "wu_password-value" }
      )
    end
  end
end
