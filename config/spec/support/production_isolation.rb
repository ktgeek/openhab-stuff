# frozen_string_literal: true

require "openhab/rspec/karaf"

# The harness clones the live instance, including its ConfigAdmin store, and every config there still names the file in
# production's etc/ it was loaded from (`felix.fileinstall.filename`). The harness then updates org.openhab.addons,
# org.openhab.persistence and org.openhab.ephemeris on startup, and the clone's fileinstall saves each update to the
# file the config names: production's. When the user running the specs can write those files, production's add-on list
# gets replaced by the specs' trimmed one and production uninstalls the rest. So make the clone refer only to itself,
# stop its fileinstall saving configs at all, and refuse to start if anything still points at production.
#
# The methods below are openhab/openhab-jruby#587 (fixes #580), copied as they are at 952fe485d. Remove this file once a
# release with that PR ships, and copy the changes over again if the PR changes before then. Even then, keep it until a
# launch has been checked against hashes of production's files, since a regression here costs data, not a failing spec.
module ProductionIsolation
  # Runs on every launch, after the clone exists and before Karaf starts, so a fresh .karaf/ is covered too.
  module CleanupInstance
    private

    # The PR calls this from the harness's own `cleanup_instance`, with the userdata directory it started from
    def cleanup_instance
      super

      isolate_clone(ENV.fetch("OPENHAB_USERDATA"))
    end

    # The clone's ConfigAdmin store still names the files of the instance it was cloned from
    # (felix.fileinstall.filename), and the clone's fileinstall saves every config update, including the ones made
    # while starting up, to the file its config names. That would rewrite the real instance's etc/*.cfg files.
    # So make the clone refer only to itself, stop it from saving configs at all, and refuse to start if anything
    # still names the real instance.
    def isolate_clone(root_userdata)
      root_userdata = File.expand_path(root_userdata)
      real_root = File.realpath(root_userdata)
      real_clone = File.realpath(path)
      if real_clone == real_root || real_clone.start_with?("#{real_root}/")
        raise ArgumentError,
              "The instance clone (#{path}) is the instance it was cloned from (#{root_userdata}), or inside it"
      end

      remove_config_backups
      repoint_configs(root_userdata)
      disable_config_save
      verify_isolation(root_userdata)
    end

    # A file reached through a symlink, its own or a parent directory's, could belong to the real instance
    def clone_file!(file)
      return file if File.realpath(file).start_with?("#{File.realpath(path)}/")

      raise "#{file} leads outside the instance clone (#{path}); refusing to change it"
    end

    # ConfigAdmin falls back to them, and they still name the real instance
    def remove_config_backups
      files_under("config").grep(/\.config\.bak\z/).each { |file| File.delete(clone_file!(file)) }
    end

    # Binary reads, since etc/ holds keystores
    def files_under(*directories)
      files = directories.flat_map do |directory|
        base = File.join(path, directory)
        Dir.glob("**/*", File::FNM_DOTMATCH, base:).map { |file| File.join(base, file) }
      end
      files.select { |file| File.file?(file) }
    end

    # The trailing "/" keeps a sibling that shares the path's prefix (/var/lib/openhab-old) from matching
    def repoint_configs(root_userdata)
      from = "#{root_userdata}/".b
      to = "#{path}/".b
      files_under("config").each do |file|
        contents = File.binread(file)
        repointed = contents.gsub(from) { to }
        File.binwrite(clone_file!(file), repointed) unless repointed == contents
      end
    end

    # Added when it's missing, so that saving is off whichever way the distribution configures it
    def disable_config_save
      file = "#{path}/etc/config.properties"
      config_save = /^(felix\.fileinstall\.enableConfigSave[ \t]*=[ \t]*)[^\r\n]*/
      properties = File.read(file)
      disabled = if properties.match?(config_save)
                   properties.sub(config_save, '\1false')
                 else
                   "#{properties.chomp}\nfelix.fileinstall.enableConfigSave = false\n"
                 end
      File.write(clone_file!(file), disabled) unless disabled == properties
    end

    def verify_isolation(root_userdata)
      needle = "#{root_userdata}/".b
      leaks = files_under("config", "etc").select { |file| File.binread(file).include?(needle) }
      return if leaks.empty?

      raise "The instance clone still refers to #{root_userdata}, and could write to it. Files: #{leaks.join(', ')}"
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(ProductionIsolation::CleanupInstance)
