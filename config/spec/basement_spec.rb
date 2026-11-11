# frozen_string_literal: true

RSpec.describe "basement.rb" do
  before { allow(TvNotification).to receive(:notify) }

  # The occupancy rules add the counters up, which fails for a counter that has never had a value. The total's rule also
  # compares it with the previous total, and the mock persistence service only remembers what a spec persists, where
  # openHAB would persist every change.
  def set_counts(basement: 0, exercise_room: 0, hallway: 0)
    suspend_rules do
      Basement_Hiome_Occupancy_Count.update(basement)
      ExerciseRoom_Hiome_Occupancy_Count.update(exercise_room)
      BasementHallway_Hiome_Occupancy_Count.update(hallway)
      Basement_Total_Occupancy.update(0)
      Basement_Deadend_Occupancy.update(0)
    end
    Basement_Total_Occupancy.persist
  end

  def all_lights_on
    suspend_rules { Basement_All_Lights.members.each { |light| light.update(ON) } }
  end

  describe "movie mode" do
    before do
      suspend_rules do
        Basement_Stairs_Switch.update(ON)
        Basement_Room_Lights_Switch.update(ON)
        Basement_TheaterLights.update(50)
        Basement_BarLights.update(50)
      end
      Basement_Movie_Switch.command(ON)
    end

    it "turns off the stairs lights" do
      expect(Basement_Stairs_Switch).to be_off
    end

    it "turns off the room lights" do
      expect(Basement_Room_Lights_Switch).to be_off
    end

    it "dims the theater lights to 9%" do
      expect(Basement_TheaterLights.state).to eq 9
    end

    it "dims the bar lights to 2%" do
      expect(Basement_BarLights.state).to eq 2
    end

    it "turns the movie switch back off after 10 seconds" do
      time_travel_and_execute_timers(10.seconds)

      expect(Basement_Movie_Switch).to be_off
    end
  end

  describe "normal mode" do
    before do
      suspend_rules do
        Basement_Stairs_Switch.update(OFF)
        Basement_TheaterLights.update(9)
        Basement_BarLights.update(2)
      end
      Basement_Normal_Switch.command(ON)
    end

    it "turns on the stairs lights" do
      expect(Basement_Stairs_Switch).to be_on
    end

    it "brings the theater lights to full" do
      expect(Basement_TheaterLights.state).to eq 100
    end

    it "brings the bar lights to full" do
      expect(Basement_BarLights.state).to eq 100
    end

    it "turns the normal switch back off after 10 seconds" do
      time_travel_and_execute_timers(10.seconds)

      expect(Basement_Normal_Switch).to be_off
    end
  end

  describe "occupancy counters" do
    before { set_counts }

    it "turns the basement sensor on when its count is positive" do
      Basement_Hiome_Occupancy_Count.update(1)

      expect(Basement_Occupancy_Sensor).to be_on
    end

    it "turns the basement sensor off when its count drops to zero" do
      Basement_Hiome_Occupancy_Count.update(1)
      Basement_Hiome_Occupancy_Count.update(0)

      expect(Basement_Occupancy_Sensor).to be_off
    end

    it "turns the exercise room sensor on when its count is positive" do
      ExerciseRoom_Hiome_Occupancy_Count.update(1)

      expect(ExerciseRoom_Occupancy_Sensor).to be_on
    end

    it "turns the hallway sensor on when its count is positive" do
      BasementHallway_Hiome_Occupancy_Count.update(1)

      expect(BasementHallway_Occupancy_Sensor).to be_on
    end

    it "adds all the counts up in the total occupancy" do
      Basement_Hiome_Occupancy_Count.update(2)
      ExerciseRoom_Hiome_Occupancy_Count.update(1)
      time_travel_and_execute_timers(1.second)

      expect(Basement_Total_Occupancy.state).to eq 3
    end

    it "adds the exercise room and hallway counts up in the deadend occupancy" do
      Basement_Hiome_Occupancy_Count.update(2)
      ExerciseRoom_Hiome_Occupancy_Count.update(1)
      BasementHallway_Hiome_Occupancy_Count.update(1)
      time_travel_and_execute_timers(1.second)

      expect(Basement_Deadend_Occupancy.state).to eq 2
    end
  end

  describe "total occupancy" do
    # The rule compares the total with the previous one, and the mock persistence service only remembers what a spec
    # persists, where openHAB would persist every change
    before do
      Basement_Total_Occupancy.update(0)
      Basement_Total_Occupancy.persist
    end

    context "when someone enters" do
      before { Basement_Total_Occupancy.update(1) }

      it "turns on the stairs lights" do
        expect(Basement_Stairs_Switch).to be_on
      end

      it "notifies the basement TV" do
        expect(TvNotification).to have_received(:notify).with(
          message: "Someone has entered the basement", only: Basement_TV_Toast, avoid_appletv: false
        )
      end
    end

    context "when the occupancy drops but someone is still there" do
      before do
        Basement_Total_Occupancy.update(2)
        Basement_Total_Occupancy.persist
        Basement_Stairs_Switch.update(OFF)
        Basement_Total_Occupancy.update(1)
      end

      it "leaves the stairs lights alone" do
        expect(Basement_Stairs_Switch).to be_off
      end

      it "only notified the basement TV when they entered" do
        expect(TvNotification).to have_received(:notify).once
      end
    end

    context "when the last person leaves" do
      before do
        Basement_Total_Occupancy.update(1)
        all_lights_on
        Basement_Total_Occupancy.update(0)
      end

      it "leaves the lights on for the first 2 minutes" do
        time_travel_and_execute_timers(119.seconds)

        expect(Basement_All_Lights.members.all?(&:on?)).to be true
      end

      it "turns all the basement lights off after 2 minutes" do
        time_travel_and_execute_timers(120.seconds)

        expect(Basement_All_Lights.members.all?(&:off?)).to be true
      end

      it "keeps the lights on if someone comes back within 2 minutes" do
        time_travel_and_execute_timers(60.seconds)
        Basement_Total_Occupancy.update(1)
        time_travel_and_execute_timers(120.seconds)

        expect(Basement_All_Lights.members.all?(&:on?)).to be true
      end
    end

    { 3 => 3, 7 => 7, 12 => 7 }.each do |occupancy, led|
      it "sets the occupancy LEDs to #{led} when #{occupancy} people are there" do
        Basement_Total_Occupancy.update(occupancy)

        expect(Basement_Occupancy_LEDs.members.map(&:state).uniq).to eq [led]
      end
    end

    it "turns the occupancy LEDs off when nobody is there" do
      Basement_Total_Occupancy.update(2)
      Basement_Total_Occupancy.update(0)

      expect(Basement_Occupancy_LEDs.members.map(&:state).uniq).to eq [0]
    end
  end

  describe "exercise room occupancy" do
    before do
      set_counts
      ExerciseRoom_Light.update(OFF)
      ExerciseRoom_BikeTrainer_Switch.update(OFF)
    end

    it "turns on the exercise room light when someone is there" do
      ExerciseRoom_Hiome_Occupancy_Count.update(1)

      expect(ExerciseRoom_Light).to be_on
    end

    it "turns on the bike trainer when someone is there and it is enabled" do
      ExerciseRoom_BikeTrainer_Enabled.update(ON)
      ExerciseRoom_Hiome_Occupancy_Count.update(1)

      expect(ExerciseRoom_BikeTrainer_Switch).to be_on
    end

    it "leaves the bike trainer off when someone is there and it is not enabled" do
      ExerciseRoom_BikeTrainer_Enabled.update(OFF)
      ExerciseRoom_Hiome_Occupancy_Count.update(1)

      expect(ExerciseRoom_BikeTrainer_Switch).to be_off
    end
  end

  describe "deadend occupancy" do
    before do
      suspend_rules do
        ExerciseRoom_Light.update(ON)
        ExerciseRoom_BikeTrainer_Switch.update(ON)
      end
      Basement_Deadend_Occupancy.update(1)
      Basement_Deadend_Occupancy.update(0)
    end

    it "leaves the exercise room light on for the first 90 seconds" do
      time_travel_and_execute_timers(89.seconds)

      expect(ExerciseRoom_Light).to be_on
    end

    it "turns off the exercise room light after 90 seconds" do
      time_travel_and_execute_timers(90.seconds)

      expect(ExerciseRoom_Light).to be_off
    end

    it "turns off the bike trainer after 90 seconds" do
      time_travel_and_execute_timers(90.seconds)

      expect(ExerciseRoom_BikeTrainer_Switch).to be_off
    end

    it "keeps the exercise room light on if someone comes back within 90 seconds" do
      time_travel_and_execute_timers(60.seconds)
      Basement_Deadend_Occupancy.update(1)
      time_travel_and_execute_timers(90.seconds)

      expect(ExerciseRoom_Light).to be_on
    end
  end

  describe "exercise room door" do
    before do
      set_counts(basement:)
      suspend_rules do
        Basement_Hallway_Lights_Switch.update(ON)
        ExerciseRoom_Light.update(ON)
        ExerciseRoom_BikeTrainer_Switch.update(ON)
        Basement_Stairs_Switch.update(ON)
        Basement_Deadend_Occupancy.update(deadend)
      end
    end

    let(:deadend) { 0 }
    let(:basement) { 0 }

    context "when it is closed with nobody in the deadend" do
      before { ExerciseRoom_Hiome_Door_Contact.update(CLOSED) }

      it "turns off the hallway lights" do
        expect(Basement_Hallway_Lights_Switch).to be_off
      end

      it "turns off the exercise room light" do
        expect(ExerciseRoom_Light).to be_off
      end

      it "turns off the bike trainer" do
        expect(ExerciseRoom_BikeTrainer_Switch).to be_off
      end
    end

    context "when it is closed with nobody in the basement" do
      before { ExerciseRoom_Hiome_Door_Contact.update(CLOSED) }

      it "turns off the stairs lights" do
        expect(Basement_Stairs_Switch).to be_off
      end
    end

    context "when it is closed with someone in the deadend" do
      let(:deadend) { 1 }

      before { ExerciseRoom_Hiome_Door_Contact.update(CLOSED) }

      it "leaves the exercise room light on" do
        expect(ExerciseRoom_Light).to be_on
      end
    end

    context "when it is closed with someone in the basement" do
      let(:basement) { 1 }

      before { ExerciseRoom_Hiome_Door_Contact.update(CLOSED) }

      it "leaves the stairs lights on" do
        expect(Basement_Stairs_Switch).to be_on
      end
    end

    context "when it is opened with nobody in the basement" do
      before do
        Basement_Stairs_Switch.update(OFF)
        ExerciseRoom_Hiome_Door_Contact.update(OPEN)
      end

      it "turns on the stairs lights" do
        expect(Basement_Stairs_Switch).to be_on
      end
    end

    context "when it is opened with someone in the basement" do
      let(:basement) { 1 }

      before do
        Basement_Stairs_Switch.update(OFF)
        ExerciseRoom_Hiome_Door_Contact.update(OPEN)
      end

      it "leaves the stairs lights off" do
        expect(Basement_Stairs_Switch).to be_off
      end
    end
  end

  describe "exercise room paddles" do
    it "turns on the stairs lights on two clicks of scene 1" do
      Basement_Stairs_Switch.update(OFF)
      ExerciseRoom_DimmerLights_Scene_1.update(ZWave::Paddle::TWO_CLICKS)

      expect(Basement_Stairs_Switch).to be_on
    end

    it "turns off the stairs lights on two clicks of scene 2" do
      Basement_Stairs_Switch.update(ON)
      ExerciseRoom_DimmerLights_Scene_2.update(ZWave::Paddle::TWO_CLICKS)

      expect(Basement_Stairs_Switch).to be_off
    end

    context "when scene 1 is clicked three times" do
      before do
        ExerciseRoom_BikeTrainer_Enabled.update(OFF)
        ExerciseRoom_BikeTrainer_Switch.update(OFF)
        ExerciseRoom_DimmerLights_Scene_1.update(ZWave::Paddle::THREE_CLICKS)
      end

      it "enables the bike trainer" do
        expect(ExerciseRoom_BikeTrainer_Enabled).to be_on
      end

      it "turns on the bike trainer" do
        expect(ExerciseRoom_BikeTrainer_Switch).to be_on
      end
    end

    context "when scene 2 is clicked three times" do
      before do
        ExerciseRoom_BikeTrainer_Enabled.update(ON)
        ExerciseRoom_BikeTrainer_Switch.update(ON)
        ExerciseRoom_DimmerLights_Scene_2.update(ZWave::Paddle::THREE_CLICKS)
      end

      it "disables the bike trainer" do
        expect(ExerciseRoom_BikeTrainer_Enabled).to be_off
      end

      it "turns off the bike trainer" do
        expect(ExerciseRoom_BikeTrainer_Switch).to be_off
      end
    end
  end

  describe "basement hallway occupancy" do
    before do
      set_counts
      Basement_Hallway_Lights_Switch.update(OFF)
    end

    it "turns on the hallway lights when someone is there" do
      BasementHallway_Hiome_Occupancy_Count.update(1)

      expect(Basement_Hallway_Lights_Switch).to be_on
    end

    context "when the hallway empties" do
      before do
        BasementHallway_Hiome_Occupancy_Count.update(1)
        BasementHallway_Hiome_Occupancy_Count.update(0)
      end

      it "leaves the hallway lights on for the first minute" do
        time_travel_and_execute_timers(59.seconds)

        expect(Basement_Hallway_Lights_Switch).to be_on
      end

      it "turns off the hallway lights after a minute" do
        time_travel_and_execute_timers(60.seconds)

        expect(Basement_Hallway_Lights_Switch).to be_off
      end

      it "keeps the hallway lights on if someone comes back within a minute" do
        time_travel_and_execute_timers(30.seconds)
        BasementHallway_Hiome_Occupancy_Count.update(1)
        time_travel_and_execute_timers(60.seconds)

        expect(Basement_Hallway_Lights_Switch).to be_on
      end
    end
  end
end
