# frozen_string_literal: true

# No binding is installed in the harness, so no thing has its thing type, and openHAB holds such things back for a
# minute or so before it initializes them. Force them to initialize once they're all registered. They get their (mock)
# handlers a few seconds after that, and the harness doesn't wait, so the examples that happen to run first would see
# things with no handler. Wait until the number of things with a handler is above zero and has stopped changing.
module ThingInitialization
  POLL_INTERVAL = 0.5
  STABLE_FOR = 3
  TIMEOUT = 30

  def self.force_missing_thing_types
    started = now
    count = OpenHAB::DSL.things.count
    stable_since = started

    while now - started < TIMEOUT
      sleep POLL_INTERVAL
      current = OpenHAB::DSL.things.count
      if current != count
        count = current
        stable_since = now
      elsif count.positive? && now - stable_since >= STABLE_FOR
        break
      end
    end

    OpenHAB::RSpec::Helpers.initialize_missing_thing_types
  end

  def self.wait
    force_missing_thing_types
    started = now
    count = handled_things
    stable_since = started

    while now - started < TIMEOUT
      sleep POLL_INTERVAL
      current = handled_things
      if current != count
        count = current
        stable_since = now
      elsif count.positive? && now - stable_since >= STABLE_FOR
        return
      end
    end

    # Without any handler every example would fail for the wrong reason, so stop instead of reporting that as results
    raise "openHAB started but no thing got a handler after #{TIMEOUT}s; the launch is bad, rerun" if count.zero?

    warn "Things were still initializing after #{TIMEOUT}s (#{count} with a handler); running the specs anyway"
  end

  def self.handled_things
    OpenHAB::DSL.things.count(&:handler)
  end

  def self.now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end

RSpec.configure do |config|
  config.before(:suite) { ThingInitialization.wait }
end
