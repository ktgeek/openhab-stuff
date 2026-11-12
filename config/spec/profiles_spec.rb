# frozen_string_literal: true

RSpec.describe "profiles.rb" do
  let(:thing_uid) { "homeassistant:device:26bcbec1ee:zigbee2mqtt_5F0x282c02bfffee018b" }
  let(:channel_uid) { org.openhab.core.thing.ChannelUID.new("#{thing_uid}:last_seen") }

  # The harness gives every example its own ProfileFactory, so the profiles register again here instead of at suite load
  before { load File.expand_path("../automation/ruby/profiles.rb", __dir__) }

  # Items are linked to a channel on a thing the harness gives a mock handler, and a state sent through that handler's
  # callback goes through the link's profile like a binding's update would. The items don't autoupdate, so their state
  # is only ever what the profile sent.
  def link_item(type, profile, **config)
    channel = channel_uid.to_s
    items.build do
      send(:"#{type}_item", "ProfileTest_Item", autoupdate: false, channel: [channel, { profile: }.merge(config)])
    end
    ProfileTest_Item
  end

  # The profile runs on openHAB's own threads, so wait for the item to change rather than for a fixed time
  def await_change(item)
    previous = item.state
    yield
    50.times do
      break if item.state != previous

      sleep 0.04
    end
  end

  def from_handler(item, state)
    await_change(item) { things[thing_uid].handler.callback.state_updated(channel_uid, state) }
  end

  describe "upcase_state" do
    it "upcases the state" do
      item = link_item(:string, "ruby:upcase_state")
      from_handler(item, StringType.new("abc"))

      expect(item.state.to_s).to eq "ABC"
    end
  end

  describe "binary_open_state" do
    let(:item) { link_item(:switch, "ruby:binary_open_state") }

    it "turns CLOSED into OFF" do
      item.update(ON)
      from_handler(item, StringType.new("CLOSED"))

      expect(item).to be_off
    end

    it "turns OPEN into ON" do
      from_handler(item, StringType.new("OPEN"))

      expect(item).to be_on
    end
  end

  describe "adjust_rainin_state" do
    it "takes 0.05 off the state" do
      item = link_item(:number, "ruby:adjust_rainin_state")
      from_handler(item, DecimalType.new(1.0))

      expect(item.state.to_f).to be_within(0.001).of(0.95)
    end
  end

  describe "number_channel_switch" do
    let(:item) { link_item(:switch, "ruby:number_channel_switch") }

    it "turns 1 from the channel into ON" do
      from_handler(item, DecimalType.new(1))

      expect(item).to be_on
    end

    it "turns 0 from the channel into OFF" do
      from_handler(item, DecimalType.new(0))

      expect(item).to be_off
    end

    it "sends 1 to the channel for an ON command" do
      await_change(item) { item.command(ON) }

      expect(item).to be_on
    end

    it "sends 0 to the channel for an OFF command" do
      item.update(ON)
      await_change(item) { item.command(OFF) }

      expect(item).to be_off
    end
  end

  describe "is_low_state" do
    context "with the default threshold" do
      let(:item) { link_item(:switch, "ruby:is_low_state") }

      it "turns a state below 20 into ON" do
        from_handler(item, DecimalType.new(10))

        expect(item).to be_on
      end

      it "turns a state of 20 into OFF" do
        from_handler(item, DecimalType.new(20))

        expect(item).to be_off
      end
    end

    context "with a configured threshold" do
      let(:item) { link_item(:switch, "ruby:is_low_state", threshold: "50") }

      it "turns a state below the threshold into ON" do
        from_handler(item, DecimalType.new(30))

        expect(item).to be_on
      end

      it "turns a state above the threshold into OFF" do
        from_handler(item, DecimalType.new(60))

        expect(item).to be_off
      end
    end
  end

  describe "round_to_int" do
    it "drops the decimals" do
      item = link_item(:number, "ruby:round_to_int")
      from_handler(item, DecimalType.new(3.7))

      expect(item.state.to_f).to eq 3
    end
  end
end
