# frozen_string_literal: true

RSpec.describe "backyard.rb" do
  describe "scene_1 (up-paddle click → lights on)" do
    it "turns on Backyard_Lights_Color" do
      Backyard_Lights_Color.update(OFF)
      Kitchen_Backyard_Lights_Scene_1.update(ZWave::Paddle::CLICK)
      expect(Backyard_Lights_Color).to be_on
    end
  end

  describe "scene_2 (down-paddle click → lights off)" do
    it "turns off Backyard_Lights_Color" do
      Backyard_Lights_Color.update(ON)
      Kitchen_Backyard_Lights_Scene_2.update(ZWave::Paddle::CLICK)
      expect(Backyard_Lights_Color).to be_off
    end
  end

  describe "feels-like temperature (changed Temperature, Humidity, or Wind Speed)" do
    before { allow(Weather).to receive(:feels_like).and_return(72.5) }

    it "updates Backyard_FeelsLike_Temperature 3 seconds after temperature changes" do
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      expect(Backyard_FeelsLike_Temperature.state.to_f).to eq(72.5)
    end

    it "waits for the 3 seconds before updating Backyard_FeelsLike_Temperature" do
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(2.seconds)
      expect(Backyard_FeelsLike_Temperature).to be_null
    end

    it "triggers when Backyard_Humidity changes" do
      Backyard_Humidity.update(80)
      time_travel_and_execute_timers(3.seconds)
      expect(Backyard_FeelsLike_Temperature.state.to_f).to eq(72.5)
    end

    it "triggers when Backyard_Wind_Speed changes" do
      Backyard_Wind_Speed.update(15)
      time_travel_and_execute_timers(3.seconds)
      expect(Backyard_FeelsLike_Temperature.state.to_f).to eq(72.5)
    end

    it "does not reschedule timer on a second change (reschedule: false)" do
      allow(Weather).to receive(:feels_like).and_return(72.5, 99.0)
      Backyard_Temperature.update(75)           # starts timer
      time_travel_and_execute_timers(1.second)
      Backyard_Wind_Speed.update(10)            # would reschedule without reschedule: false
      time_travel_and_execute_timers(2.seconds) # original timer fires
      expect(Weather).to have_received(:feels_like).once
    end

    context "with all three readings known" do
      before do
        suspend_rules do
          Backyard_Temperature.update(80)
          Backyard_Humidity.update(65)
          Backyard_Wind_Speed.update(10)
        end
        Backyard_Temperature.update(81)
        time_travel_and_execute_timers(3.seconds)
      end

      it "passes the current item states to Weather.feels_like" do
        expect(Weather).to have_received(:feels_like).with(
          temp: Backyard_Temperature.state,
          humidity: Backyard_Humidity.state,
          wind_speed: Backyard_Wind_Speed.state
        )
      end
    end
  end

  describe "dew point (changed Temperature or Humidity)" do
    before { allow(Weather).to receive(:dew_point).and_return(55.0) }

    it "updates Backyard_Dew_Point 3 seconds after temperature changes" do
      suspend_rules { Backyard_Humidity.update(70) }
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      expect(Backyard_Dew_Point.state.to_f).to eq(55.0)
    end

    it "updates Backyard_Dew_Point 3 seconds after humidity changes" do
      suspend_rules { Backyard_Temperature.update(75) }
      Backyard_Humidity.update(70)
      time_travel_and_execute_timers(3.seconds)
      expect(Backyard_Dew_Point.state.to_f).to eq(55.0)
    end

    it "does not update until both temperature and humidity are known" do
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      expect(Weather).not_to have_received(:dew_point)
    end

    it "passes current item states to Weather.dew_point" do
      suspend_rules do
        Backyard_Temperature.update(78)
        Backyard_Humidity.update(60)
      end
      Backyard_Humidity.update(65)
      time_travel_and_execute_timers(3.seconds)
      expect(Weather).to have_received(:dew_point).with(
        temp: Backyard_Temperature.state,
        humidity: Backyard_Humidity.state
      )
    end
  end

  describe "every 1.minute weather monitor" do
    let(:every_minute_rule) { rules["backyard_weather_monitor"] }

    before do
      allow(Weather).to receive(:post_to_weather_services)
      allow(Notification).to receive(:send)
      # Reset the no_update_notification_sent closure variable to false by
      # firing the rule with a recent last_update (< 1 minute ago)
      Backyard_Last_Updated.update(ZonedDateTime.now - 30.seconds)
      every_minute_rule.trigger
      allow(Notification).to receive(:send) # reset call count after setup
    end

    context "when last update is more than 2 hours ago" do
      before { Backyard_Last_Updated.update(ZonedDateTime.now - 3.hours) }

      it "sends a stale-data notification" do
        every_minute_rule.trigger
        expect(Notification).to have_received(:send).with(a_string_including("not updated"))
      end

      it "does not post weather data" do
        every_minute_rule.trigger
        expect(Weather).not_to have_received(:post_to_weather_services)
      end

      it "does not send a second notification on the next tick (deduplication)" do
        every_minute_rule.trigger # first: sends notification, sets flag
        every_minute_rule.trigger # second: flag set, should not resend
        expect(Notification).to have_received(:send).once
      end
    end

    context "when last update is between 1 minute and 2 hours ago" do
      before { Backyard_Last_Updated.update(ZonedDateTime.now - 90.minutes) }

      it "does not send a notification" do
        every_minute_rule.trigger
        expect(Notification).not_to have_received(:send)
      end

      it "does not post weather data" do
        every_minute_rule.trigger
        expect(Weather).not_to have_received(:post_to_weather_services)
      end
    end

    context "when the last update is unknown" do
      before { Backyard_Last_Updated.update(NULL) }

      it "does not send a notification" do
        every_minute_rule.trigger
        expect(Notification).not_to have_received(:send)
      end

      it "does not post weather data" do
        every_minute_rule.trigger
        expect(Weather).not_to have_received(:post_to_weather_services)
      end
    end

    context "when last update is within the last minute" do
      let(:readings) do
        { tempf: 78.4, humidity: 62, baromin: 29.92, winddir: 180, windspeedmph: 8.0, dewptf: 63.1, UV: 3 }
      end

      before do
        Backyard_Last_Updated.update(ZonedDateTime.now - 30.seconds)
        suspend_rules do
          Backyard_Temperature.update(78.4)
          Backyard_Humidity.update(62)
          Backyard_Barometric_Pressure.update(29.92)
          Backyard_Wind_Direction.update(180)
          Backyard_Wind_Speed.update(8.0)
          Backyard_Dew_Point.update(63.1)
          Backyard_Rain.update(0.0)
          Backyard_UV.update(3)
        end
      end

      it "posts weather data to services" do
        every_minute_rule.trigger
        expect(Weather).to have_received(:post_to_weather_services)
      end

      it "does not send a notification" do
        every_minute_rule.trigger
        expect(Notification).not_to have_received(:send)
      end

      it "includes the current readings in the weather post" do
        every_minute_rule.trigger
        expect(Weather).to have_received(:post_to_weather_services).with(hash_including(readings))
      end

      it "formats dateutc as a UTC timestamp string" do
        every_minute_rule.trigger
        expect(Weather).to have_received(:post_to_weather_services).with(
          hash_including(dateutc: match(/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/))
        )
      end

      it "includes windgustmph (60-minute max) and windspdmph_avg2m in post" do
        every_minute_rule.trigger
        expect(Weather).to have_received(:post_to_weather_services).with(
          hash_including(:windgustmph, :windspdmph_avg2m)
        )
      end

      it "includes rainin and dailyrainin in post" do
        every_minute_rule.trigger
        expect(Weather).to have_received(:post_to_weather_services).with(
          hash_including(:rainin, :dailyrainin)
        )
      end

      it "does not post when a reading is unknown" do
        Backyard_UV.update(NULL)
        every_minute_rule.trigger
        expect(Weather).not_to have_received(:post_to_weather_services)
      end

      it "resets no_update_notification_sent so a future stale tick sends a new notification" do
        Backyard_Last_Updated.update(ZonedDateTime.now - 3.hours)
        every_minute_rule.trigger # sets flag = true

        Backyard_Last_Updated.update(ZonedDateTime.now - 30.seconds)
        every_minute_rule.trigger # resets flag = false

        Backyard_Last_Updated.update(ZonedDateTime.now - 3.hours)
        every_minute_rule.trigger # should send again now that flag is reset
        expect(Notification).to have_received(:send).twice
      end
    end
  end

  describe "Awtrix outdoor temp text" do
    before do
      allow(Weather).to receive(:feels_like).and_return(feels_like)
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
    end

    context "when the temperature is shorter than 5 characters" do
      let(:feels_like) { 72.5 }

      it "includes the °F unit on the office clock" do
        expect(Office_Awtrix_OutdoorTemp_Text.state.to_s).to eq("72.5°F")
      end

      it "includes the °F unit on the bedroom clock" do
        expect(Bedroom_Awtrix_OutdoorTemp_Text.state.to_s).to eq("72.5°F")
      end
    end

    context "when the temperature is 5 characters long" do
      let(:feels_like) { 100.4 }

      it "omits the °F unit on the office clock" do
        expect(Office_Awtrix_OutdoorTemp_Text.state.to_s).to eq("100.4")
      end

      it "omits the °F unit on the bedroom clock" do
        expect(Bedroom_Awtrix_OutdoorTemp_Text.state.to_s).to eq("100.4")
      end
    end
  end

  # The color scale itself is covered by spec/lib/color_spec.rb
  describe "Office Awtrix outdoor temp color" do
    # Any freezing of the clock has to come first, or the timer would be due in the real present
    def update_feels_like
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
    end

    before { allow(Weather).to receive(:feels_like).and_return(55) }

    it "is the color for the feels-like temperature" do
      update_feels_like
      expect(Office_Awtrix_OutdoorTemp_Color.state).to eq(Color.for_temperature(55))
    end

    it "is not changed by sleeping hours" do
      Timecop.freeze(Time.local(2023, 7, 10, 23, 0, 0))
      update_feels_like
      expect(Office_Awtrix_OutdoorTemp_Color.state).to eq(Color.for_temperature(55))
    end
  end

  describe "Bedroom Awtrix outdoor temp color" do
    let(:sleep_rule) { rules["backyard_outdoor_temp_color_sleep"] }
    let(:clock_default) { OpenHAB::Core::Types::HSBType.new(9, 100, 71) }

    def bedroom_color_for(feels_like)
      allow(Weather).to receive(:feels_like).and_return(feels_like)
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      Bedroom_Awtrix_OutdoorTemp_Color.state
    end

    before { Bedroom_AwtrixClock_TextColor.update(clock_default) }

    { "7:00" => [7, 0], "12:00" => [12, 0], "21:29" => [21, 29] }.each do |label, (hour, minute)|
      it "follows the temperature at #{label}" do
        Timecop.freeze(Time.local(2023, 7, 10, hour, minute, 0))
        expect(bedroom_color_for(-25)).to eq(Color.for_temperature(-25))
      end
    end

    { "21:30" => [21, 30], "23:59" => [23, 59], "0:00" => [0, 0], "6:59" => [6, 59] }.each do |label, (hour, minute)|
      it "uses the clock's default text color at #{label}" do
        Timecop.freeze(Time.local(2023, 7, 10, hour, minute, 0))
        expect(bedroom_color_for(-25)).to eq(clock_default)
      end
    end

    it "is left alone overnight when the clock's default text color is unknown" do
      Timecop.freeze(Time.local(2023, 7, 10, 23, 0, 0))
      Bedroom_AwtrixClock_TextColor.update(NULL)
      bedroom_color_for(-25)
      expect(Bedroom_Awtrix_OutdoorTemp_Color.state?).to be false
    end

    context "with the 9:30pm and 7am schedule" do
      before { Backyard_FeelsLike_Temperature.update(-25) }

      it "switches to the clock's default text color without a weather change" do
        Timecop.freeze(Time.local(2023, 7, 10, 21, 30, 0))
        sleep_rule.trigger
        expect(Bedroom_Awtrix_OutdoorTemp_Color.state).to eq(clock_default)
      end

      it "switches back to the temperature color without a weather change" do
        Timecop.freeze(Time.local(2023, 7, 11, 7, 0, 0))
        sleep_rule.trigger
        expect(Bedroom_Awtrix_OutdoorTemp_Color.state).to eq(Color.for_temperature(-25))
      end

      it "does nothing before a feels-like temperature is known" do
        Backyard_FeelsLike_Temperature.update(NULL)
        sleep_rule.trigger
        expect(Bedroom_Awtrix_OutdoorTemp_Color.state?).to be false
      end
    end
  end

  describe "weather overlay" do
    let(:overlay_rule) { rules["backyard_weather_overlay"] }

    before do
      Backyard_Temperature.update(50)
      Bedroom_AwtrixClock_Overlay.update("snow")
      Office_AwtrixClock_Overlay.update("snow")
    end

    it "sets the bedroom overlay for the reported conditions" do
      allow(Weather).to receive(:current_conditions).and_return(":L:R")

      overlay_rule.trigger

      expect(Bedroom_AwtrixClock_Overlay.state.to_s).to eq("drizzle")
    end

    it "sets the office overlay for the reported conditions" do
      allow(Weather).to receive(:current_conditions).and_return(":L:R")

      overlay_rule.trigger

      expect(Office_AwtrixClock_Overlay.state.to_s).to eq("drizzle")
    end

    it "stores the reported code" do
      allow(Weather).to receive(:current_conditions).and_return(":L:R")

      overlay_rule.trigger

      expect(Backyard_Weather_Condition.state.to_s).to eq(":L:R")
    end

    it "shows frost when the sky is clear and it is freezing" do
      Backyard_Temperature.update(30)
      allow(Weather).to receive(:current_conditions).and_return("")

      overlay_rule.trigger

      expect(Bedroom_AwtrixClock_Overlay.state.to_s).to eq("frost")
    end

    it "clears the overlay when the sky is clear and it is warm" do
      allow(Weather).to receive(:current_conditions).and_return("")

      overlay_rule.trigger

      expect(Bedroom_AwtrixClock_Overlay.state.to_s).to eq("")
    end

    it "clears the overlay when the sky is clear and the temperature is unknown" do
      Backyard_Temperature.update(NULL)
      allow(Weather).to receive(:current_conditions).and_return("")

      overlay_rule.trigger

      expect(Bedroom_AwtrixClock_Overlay.state.to_s).to eq("")
    end

    context "when the lookup fails while freezing" do
      before do
        Backyard_Temperature.update(20)
        Backyard_Weather_Condition.update(":L:R")
        allow(Weather).to receive(:current_conditions).and_return(nil)
        overlay_rule.trigger
      end

      it "clears the bedroom overlay" do
        expect(Bedroom_AwtrixClock_Overlay.state.to_s).to eq("")
      end

      it "clears the office overlay" do
        expect(Office_AwtrixClock_Overlay.state.to_s).to eq("")
      end

      it "clears the condition" do
        expect(Backyard_Weather_Condition).to be_null
      end
    end
  end
end
