# frozen_string_literal: true

require "openhab/rspec/karaf"

# The harness clones the live instance into .karaf/ once and reuses it, along with production's addon settings. At
# startup Karaf is asked to install all of them in one request, and that request fails as a whole: the jinja
# transformation can't resolve javassist in the harness's trimmed-down runtime. Installing a binding also puts a bundle
# in the runtime that must never start, and no spec needs one: things get the harness's mock handler either way. So
# drop every addon setting from the clone on every launch. A spec that needs an addon's thing types can call
# `install_addon "binding-x"` itself.
module KarafAddons
  CATEGORIES = %w[package binding ui persistence action transformation voice misc automation
                  core-config-discovery-addon].freeze

  # `binding = a,b` in the .cfg, `binding="a,b"` in the ConfigurationAdmin store
  SETTING = /\A(?:#{Regexp.union(CATEGORIES)})\s*=/

  def self.strip(settings)
    settings.each_line.grep_v(SETTING).join
  end

  # Runs on every launch, after the clone exists and before Karaf starts, so a fresh .karaf/ is covered too.
  module CleanupInstance
    # Relative to the clone's userdata directory
    SETTINGS_FILES = %w[etc/org.openhab.addons.cfg config/org/openhab/addons.config].freeze

    private

    def cleanup_instance
      super

      strip_addon_settings
    end

    def strip_addon_settings
      SETTINGS_FILES.each do |file|
        clone = File.join(path, file)
        next unless File.exist?(clone)

        settings = File.read(clone)
        stripped = KarafAddons.strip(settings)
        File.write(clone, stripped) unless stripped == settings
      end
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(KarafAddons::CleanupInstance)
