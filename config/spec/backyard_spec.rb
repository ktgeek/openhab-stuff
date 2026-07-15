# frozen_string_literal: true

RSpec.describe "backyard.rb" do
  describe "Backyard Lights" do
    it "turns on all members of front lights on when one is sent ON" do
      FamilyRoom_Backyard_Lights_Switch.update(ON)

      expect(Backyard_Lights.members.all?(&:on?)).to be true
    end

    it "turns on all members of front lights off when one is sent OFF" do
      Kitchen_Backyard_Lights_Switch.update(OFF)

      expect(Backyard_Lights.members.all?(&:off?)).to be true
    end
  end

  describe "scene_1 (up-paddle click → lights on)" do
    it "turns on Backyard_Lights_Power" do
      Backyard_Lights_Power.update(OFF)
      trigger_channel("mqtt:topic:26bcbec1ee:27cfce6609:scene_1",
                      ZWave::Paddle::CLICK.to_s)
      expect(Backyard_Lights_Power).to be_on
    end
  end

  describe "scene_2 (down-paddle click → lights off)" do
    it "turns off Backyard_Lights_Power" do
      Backyard_Lights_Power.update(ON)
      trigger_channel("mqtt:topic:26bcbec1ee:27cfce6609:scene_2",
                      ZWave::Paddle::CLICK.to_s)
      expect(Backyard_Lights_Power).to be_off
    end
  end

  describe "feels-like temperature (changed Temperature, Humidity, or Wind Speed)" do
    before { allow(Weather).to receive(:feels_like).and_return(72.5) }

    it "updates Backyard_FeelsLike_Temperature 3 seconds after temperature changes" do
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      expect(Backyard_FeelsLike_Temperature.state.to_f).to eq(72.5)
    end

    it "commands Office_Awtrix_OutdoorTemp_Text with formatted reading" do
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      expect(Office_Awtrix_OutdoorTemp_Text.state.to_s).to eq("72.5°F")
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

    it "passes current item states to Weather.feels_like" do
      suspend_rules do
        Backyard_Temperature.update(80)
        Backyard_Humidity.update(65)
        Backyard_Wind_Speed.update(10)
      end
      Backyard_Temperature.update(81)
      time_travel_and_execute_timers(3.seconds)
      expect(Weather).to have_received(:feels_like).with(
        temp: Backyard_Temperature.state,
        humidity: Backyard_Humidity.state,
        wind_speed: Backyard_Wind_Speed.state
      )
    end

    it "does not reschedule timer on a second change (reschedule: false)" do
      allow(Weather).to receive(:feels_like).and_return(72.5, 99.0)
      Backyard_Temperature.update(75)           # starts timer
      time_travel_and_execute_timers(1.second)
      Backyard_Wind_Speed.update(10)            # would reschedule without reschedule: false
      time_travel_and_execute_timers(2.seconds) # original timer fires
      expect(Weather).to have_received(:feels_like).once
    end
  end

  describe "dew point (changed Temperature or Humidity)" do
    before { allow(Weather).to receive(:dew_point).and_return(55.0) }

    it "updates Backyard_Dew_Point 3 seconds after temperature changes" do
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      expect(Backyard_Dew_Point.state.to_f).to eq(55.0)
    end

    it "updates Backyard_Dew_Point 3 seconds after humidity changes" do
      Backyard_Humidity.update(70)
      time_travel_and_execute_timers(3.seconds)
      expect(Backyard_Dew_Point.state.to_f).to eq(55.0)
    end

    it "does NOT update when only wind speed changes" do
      Backyard_Wind_Speed.update(10)
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
    let(:every_minute_rule) { rules["backyard:33"] }

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

    context "when last update is within the last minute" do
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

      it "includes all required params in the weather post" do
        every_minute_rule.trigger
        expect(Weather).to have_received(:post_to_weather_services).with(
          hash_including(
            :dateutc,
            tempf: 78.4,
            humidity: 62,
            baromin: 29.92,
            winddir: 180,
            windspeedmph: 8.0,
            dewptf: 63.1,
            UV: 3
          )
        )
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

      it "resets no_update_notification_sent so a future stale tick sends a new notification" do
        Backyard_Last_Updated.update(ZonedDateTime.now - 3.hours)
        every_minute_rule.trigger # sets flag = true

        Backyard_Last_Updated.update(ZonedDateTime.now - 30.seconds)
        every_minute_rule.trigger # resets flag = false

        Backyard_Last_Updated.update(ZonedDateTime.now - 3.hours)
        every_minute_rule.trigger # should send again now that flag is reset
        expect(Notification).to have_received(:send)
      end
    end
  end

  describe "Office Awtrix outdoor temp text" do
    it "includes the °F unit when the temperature is shorter than 5 characters" do
      allow(Weather).to receive(:feels_like).and_return(72.5)
      Backyard_Temperature.update(75)
      time_travel_and_execute_timers(3.seconds)
      expect(Office_Awtrix_OutdoorTemp_Text.state.to_s).to eq("72.5°F")
    end

    it "omits the °F unit when the temperature is 5 characters long" do
      allow(Weather).to receive(:feels_like).and_return(100.4)
      Backyard_Temperature.update(101)
      time_travel_and_execute_timers(3.seconds)
      expect(Office_Awtrix_OutdoorTemp_Text.state.to_s).to eq("100.4")
    end
  end
end
