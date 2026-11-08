# frozen_string_literal: true

require "openhab/rspec/karaf"

# The harness clones the live instance into .karaf/ once and reuses it, along with production's addon settings. At
# startup Karaf is asked to install all of them in one request, and that request fails as a whole: the jinja
# transformation can't resolve javassist in the harness's trimmed-down runtime. So no addon was ever installed and every
# run logged resolver errors. Keep only the addons the specs need instead. The clone's settings are rebuilt from
# production's on every launch, so editing ALLOWED always takes effect.
module KarafAddons
  # Addon category => the entries to keep. Every other entry, and every category not listed, is dropped.
  ALLOWED = { "binding" => %w[homeassistant mqtt zwavejs] }.freeze

  CATEGORIES = %w[package binding ui persistence action transformation voice misc automation
                  core-config-discovery-addon].freeze

  # `binding = a,b` in the .cfg, `binding="a,b"` (CRLF line endings) in the ConfigurationAdmin store
  SETTING = /
    \A(?<key>#{Regexp.union(CATEGORIES)})
    (?<equals>\s*=\s*)
    (?<quote>"?)(?<value>[^"\r\n]*)\k<quote>
    (?<eol>\r?\n?)\z
  /x

  # `target` without its addon settings, plus the allowed ones from `source` (production's copy of the same file)
  def self.rewrite(target, source)
    allowed = source.each_line.filter_map do |line|
      match = SETTING.match(line)
      allowed_setting(match) if match
    end

    target.each_line.grep_v(SETTING).push(*allowed).join
  end

  def self.allowed_setting(match)
    kept = match[:value].split(",").map(&:strip) & ALLOWED.fetch(match[:key], [])
    return if kept.empty?

    "#{match[:key]}#{match[:equals]}#{match[:quote]}#{kept.join(',')}#{match[:quote]}#{match[:eol]}"
  end
  private_class_method :allowed_setting

  # Features the harness's trimmed-down openhab-runtime-base leaves out but the allowed addons import packages from:
  # zwavejs needs org.openhab.core.config.discovery.mdns. Without it the first install request fails to resolve, and
  # only succeeds on a retry once core has installed its discovery addons.
  BASE_FEATURES = %w[openhab-core-io-transport-mdns].freeze

  # Runs on every launch, after the clone exists and before Karaf starts, so a fresh .karaf/ is covered too.
  module CleanupInstance
    # Production's file and the clone's, relative to each instance's userdata directory
    SETTINGS_FILES = %w[etc/org.openhab.addons.cfg config/org/openhab/addons.config].freeze

    private

    def cleanup_instance
      super

      rewrite_addon_settings
      add_base_features
    end

    def rewrite_addon_settings
      SETTINGS_FILES.each do |file|
        clone = File.join(path, file)
        next unless File.exist?(clone)

        production = File.join(ENV.fetch("OPENHAB_USERDATA"), file)
        source = File.exist?(production) ? File.read(production) : ""
        rewritten = KarafAddons.rewrite(File.read(clone), source)
        File.write(clone, rewritten) unless rewritten == File.read(clone)
      end
    end

    # The harness regenerates this file on every launch with its replacement for openhab-runtime-base
    def add_base_features
      file = File.join(path, "etc/org.apache.karaf.features.xml")
      xml = File.read(file)
      missing = BASE_FEATURES.reject { |name| xml.include?("<f:feature>#{name}</f:feature>") }
      return if missing.empty?

      with_features = xml.sub(%r{^(?<indent> *)<f:feature>openhab-core-base</f:feature>\n}) do |line|
        indent = Regexp.last_match[:indent]
        line + missing.map { |name| "#{indent}<f:feature>#{name}</f:feature>\n" }.join
      end
      raise "no openhab-core-base feature to anchor #{missing.join(', ')} in #{file}" if with_features == xml

      File.write(file, with_features)
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(KarafAddons::CleanupInstance)
