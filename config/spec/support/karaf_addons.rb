# frozen_string_literal: true

require "openhab/rspec/karaf"

# The harness clones the live instance into .karaf/ once and reuses it, along with production's addon settings. At
# startup Karaf is asked to install all of them in one request, and that request fails as a whole: the jinja
# transformation can't resolve javassist in the harness's trimmed-down runtime. So no addon was ever installed and every
# run logged resolver errors. Keep only the addons the specs need instead; `rm -rf .karaf` re-clones if the clone is
# ever in doubt.
module KarafAddons
  # Addon category => the entries to keep. Every other entry, and every category not listed, is dropped.
  ALLOWED = {}.freeze

  CATEGORIES = %w[package binding ui persistence action transformation voice misc automation
                  core-config-discovery-addon].freeze

  # `binding = a,b` in the .cfg, `binding="a,b"` (CRLF line endings) in the ConfigurationAdmin store
  SETTING = /
    \A(?<key>#{Regexp.union(CATEGORIES)})
    (?<equals>\s*=\s*)
    (?<quote>"?)(?<value>[^"\r\n]*)\k<quote>
    (?<eol>\r?\n?)\z
  /x

  def self.filter(contents)
    contents.each_line.filter_map do |line|
      match = SETTING.match(line)
      next line unless match

      kept = match[:value].split(",").map(&:strip) & ALLOWED.fetch(match[:key], [])
      next if kept.empty?

      "#{match[:key]}#{match[:equals]}#{match[:quote]}#{kept.join(',')}#{match[:quote]}#{match[:eol]}"
    end.join
  end

  # Runs on every launch, after the clone exists and before Karaf starts, so a fresh .karaf/ is covered too.
  module CleanupInstance
    private

    def cleanup_instance
      super

      [File.join(path, "etc/org.openhab.addons.cfg"), File.join(felix_cm, "org/openhab/addons.config")].each do |file|
        next unless File.exist?(file)

        contents = File.read(file)
        filtered = KarafAddons.filter(contents)
        File.write(file, filtered) unless filtered == contents
      end
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(KarafAddons::CleanupInstance)
