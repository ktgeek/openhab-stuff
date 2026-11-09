# frozen_string_literal: true

# openhab-scripting 5.52.0's executor mock starts every submit and execute with `OpenHAB::Core.version < "5.1.0"`, a
# guard for openHAB older than 5.1. OpenHAB::Core only exists once `openhab/dsl` is required, which the harness does
# after startup, but the mock is the thread pool for every component from the moment org.openhab.core starts. So when a
# component such as XmlThingTypeProvider activated first, the NameError left it without thing types, no thing got a
# handler, and about one launch in five produced a wall of bogus failures. Define a version that is good enough for
# that guard (we run 5.3); `openhab/core.rb` replaces it with the real one when it loads.
#
# Replacing the executor's submit and execute instead leaves rules running on a pool thread rather than synchronously.
module OpenHAB
  module Core
    def self.version
      Gem::Version.new("5.1.0")
    end
  end
end
