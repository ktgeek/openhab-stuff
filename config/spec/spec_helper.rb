# frozen_string_literal: true

require "rubygems"
require "bundler"

Bundler.require(:default, :test)

require_relative "support/karaf_addons"
require_relative "support/production_isolation"
require_relative "support/readable_clone"
require_relative "support/core_version"
require "openhab/rspec"
require_relative "support/thing_initialization"
require_relative "support/mock_persistence"
require_relative "support/awtrix_clocks"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random

  Kernel.srand config.seed

  # openhab-scripting's harness only drops a timer from the TimerManager once its block returns. A timer whose block
  # raised stays registered, and the harness's own after hook (TimerManager#cancel_all) then loops on it forever.
  # Dropping those first lets the error surface as an ordinary example failure instead of a hung suite.
  # Reported as openhab/openhab-jruby#583; remove this hook once a fix ships.
  config.after do
    timers = OpenHAB::DSL::TimerManager.instance.instance_variable_get(:@timers)
    timers.keys.to_a.select(&:terminated?).each { |timer| OpenHAB::DSL.timers.delete(timer) }
  end
end
