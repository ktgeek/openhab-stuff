# frozen_string_literal: true

require "openhab/rspec/karaf"

# The harness clones the live instance into .karaf/ once and reuses it, along with production's addon settings. Bindings
# are installed so their XML and storage-based type providers describe things the way production does, but the harness
# never starts them (their bundles are in a blocked tree) and gives things its mock handler factory instead. Every other
# addon category is dropped: the harness removes or blocks them anyway, and some of them (automation, discovery) aren't
# covered by that. The clone's settings are rebuilt from production's on every launch, so a change in production's
# bindings, or in this file, always takes effect.
module KarafAddons
  CATEGORIES = %w[package binding ui persistence action transformation voice misc automation
                  core-config-discovery-addon].freeze

  # `binding = a,b` in the .cfg, `binding="a,b"` in the ConfigurationAdmin store
  SETTING = /\A(?:#{Regexp.union(CATEGORIES)})\s*=/
  BINDING_SETTING = /\Abinding\s*=/

  # `target` without its addon settings, plus the binding setting from `source` (production's copy of the same file)
  def self.rewrite(target, source)
    kept = target.each_line.grep_v(SETTING)
    bindings = source.each_line.grep(BINDING_SETTING)

    [*kept, *bindings].map { |line| line.end_with?("\n") ? line : "#{line}\n" }.join
  end

  # Runs on every launch, after the clone exists and before Karaf starts, so a fresh .karaf/ is covered too.
  module CleanupInstance
    # Relative to a userdata directory, production's and the clone's
    SETTINGS_FILES = %w[etc/org.openhab.addons.cfg config/org/openhab/addons.config].freeze

    # pax-url's local repository, where Karaf looks before it downloads a bundle. The clone's starts out empty, and
    # production's already holds the bindings it runs (141 MB), so copy them over instead of fetching from the network.
    MAVEN_REPOSITORY = "tmp/mvn"

    private

    def cleanup_instance
      super

      rewrite_addon_settings
      copy_maven_repository
    end

    # The harness records production's userdata before it points openhab.userdata at the clone
    def production_userdata
      @root_userdata || ENV.fetch("OPENHAB_USERDATA")
    end

    def rewrite_addon_settings
      SETTINGS_FILES.each do |file|
        clone = File.join(path, file)
        next unless File.exist?(clone)

        production = File.join(production_userdata, file)
        source = File.exist?(production) ? File.read(production) : ""
        settings = File.read(clone)
        rewritten = KarafAddons.rewrite(settings, source)
        File.write(clone, rewritten) unless rewritten == settings
      end
    end

    # Only what is missing, or has changed size, so a launch after the first copies next to nothing and an upgrade's new
    # versions come across on the next one.
    def copy_maven_repository
      source = File.join(production_userdata, MAVEN_REPOSITORY)
      return warn "No #{source}; the bindings will be downloaded" unless Dir.exist?(source)

      Dir.glob("**/*", base: source).each do |relative|
        from = File.join(source, relative)
        to = File.join(path, MAVEN_REPOSITORY, relative)
        next unless File.file?(from)
        next if File.exist?(to) && File.size(to) == File.size(from)

        FileUtils.mkdir_p(File.dirname(to))
        FileUtils.cp(from, to)
      rescue Errno::EACCES
        warn "Can't read #{from}; it will be downloaded if a binding needs it"
      end
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(KarafAddons::CleanupInstance)
