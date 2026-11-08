# frozen_string_literal: true

# Things only get their (mock) handlers a few seconds after Karaf reports started, and the harness doesn't wait, so the
# examples that happen to run first would see things with no handler. Wait until the number of things with a handler is
# above zero and has stopped changing. Things whose binding can't be installed never get one, so waiting for every
# thing to initialize would never end.
module ThingInitialization
  POLL_INTERVAL = 0.5
  STABLE_FOR = 3
  TIMEOUT = 30

  def self.wait
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
