# frozen_string_literal: true

require "openhab/rspec/karaf"

# The harness clones the live instance, including its ConfigAdmin store, and every config there still names the file in
# production's etc/ it was loaded from (`felix.fileinstall.filename`). The harness then updates org.openhab.addons,
# org.openhab.persistence and org.openhab.ephemeris on startup, and the clone's fileinstall saves each update to the
# file the config names: production's. When the user running the specs can write those files, production's add-on list
# gets replaced by the specs' trimmed one and production uninstalls the rest. So make the clone refer only to itself,
# stop its fileinstall saving configs at all, and refuse to start if anything still points at production.
module ProductionIsolation
  # Written as `felix.fileinstall.enableConfigSave = true` in the clone's etc/config.properties
  CONFIG_SAVE = /^(?<key>felix\.fileinstall\.enableConfigSave\s*=\s*)(?:true|false)$/

  # Runs on every launch, after the clone exists and before Karaf starts, so a fresh .karaf/ is covered too.
  module CleanupInstance
    private

    def cleanup_instance
      super

      repoint_configs_at_clone
      disable_config_save
      verify_isolation
    end

    def production_userdata
      ENV.fetch("OPENHAB_USERDATA")
    end

    # Only production's userdata directory itself, not a sibling that shares its prefix
    def production_path
      %r{#{Regexp.escape(production_userdata)}(?=/)}
    end

    # Binary reads, since etc/ holds keystores
    def files_under(*directories)
      directories.flat_map { |directory| Dir.glob(File.join(path, directory, "**/*"), File::FNM_DOTMATCH) }
                 .select { |file| File.file?(file) }
    end

    # The .config.bak copies too: ConfigAdmin falls back to them
    def repoint_configs_at_clone
      files_under("config").each do |file|
        contents = File.binread(file)
        repointed = contents.gsub(production_path, path)
        File.binwrite(file, repointed) unless repointed == contents
      end
    end

    def disable_config_save
      file = File.join(path, "etc/config.properties")
      properties = File.read(file)
      raise "no felix.fileinstall.enableConfigSave to disable in #{file}" unless properties.match?(CONFIG_SAVE)

      disabled = properties.sub(CONFIG_SAVE) { "#{Regexp.last_match(:key)}false" }
      File.write(file, disabled) unless disabled == properties
    end

    def verify_isolation
      leaks = files_under("config", "etc").select { |file| File.binread(file).match?(production_path) }
      return if leaks.empty?

      raise "the instance clone still refers to #{production_userdata}, and could write to it. Files: " \
            "#{leaks.join(', ')}"
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(ProductionIsolation::CleanupInstance)
