# frozen_string_literal: true

# The Awtrix clocks get their actions from a real thing handler, and the harness's mock handlers provide none, so
# thing.actions("mqtt.awtrixlight") is nil and any rule that lights an indicator (lock_rules, garage) raised
# NoMethodError whenever a spec happened to trigger it. Give every example a stand-in clock group by default; specs that
# assert on the clocks stub Awtrix.all_clocks themselves, which overrides this.
RSpec.configure do |config|
  config.before do
    next unless defined?(Awtrix)

    clocks = instance_double(Awtrix::ClockGroup, show_custom_notification: nil, set_indicator_color: nil)
    allow(Awtrix).to receive(:all_clocks).and_return(clocks)
  end
end
