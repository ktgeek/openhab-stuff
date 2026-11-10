# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "openhab/rspec/karaf"

# The harness clones the live instance with Karaf's own `cloneInstance`, which copies everything under production's
# userdata directory and dies on the first thing the user running the specs can't read: a `Permission denied` for a
# file, a NullPointerException for a directory. openHAB creates such entries itself and with explicit modes, so a umask
# can't help: the GraalPy runtime's `tmp/org.graalvm.python.vfsx*` (0700, renamed on every start) and
# `openhab-start-level` (0600). So hand Karaf a stand-in for production's userdata for the first clone: real
# directories holding symlinks to the readable files, which Karaf copies as ordinary files.
#
# Reported as openhab/openhab-jruby#581; remove this once a fix ships.
module ReadableClone
  # Left out of the stand-in altogether. The harness deletes the cache before it starts the clone.
  EXCLUDED = %w[cache openhab-start-level].freeze

  # Kept as an empty directory: the clone's java.io.tmpdir is inside it, and the harness empties it before it starts
  EMPTY_DIRECTORIES = %w[tmp].freeze

  module CreateInstance
    private

    # Karaf records the clone in the instance list the harness keeps in the clone's own directory, and the harness
    # returns early from there once it has one, so only the first launch builds a stand-in.
    def create_instance
      return super if clone_registered? || root_location.nil?

      userdata = root_location
      stand_in = Dir.mktmpdir("rspec-userdata")
      mirror(userdata, stand_in, top_level: true)
      replace_in_instance_list(userdata, stand_in)
      super
    ensure
      if stand_in
        replace_in_instance_list(stand_in, userdata)
        FileUtils.rm_rf(stand_in)
      end
    end

    def instance_list
      File.join(path, "instances/instance.properties")
    end

    def clone_registered?
      File.exist?(instance_list) && File.read(instance_list).match?(/^item\.\d+\.name\s*=\s*rspec\s*$/)
    end

    # The root instance is production's, listed as `item.N.root = true` with its `item.N.loc` directory
    def root_location
      return unless File.exist?(instance_list)

      properties = File.read(instance_list)
      index = properties[/^item\.(\d+)\.root\s*=\s*true\s*$/, 1]
      properties[/^item\.#{index}\.loc\s*=\s*(.+?)\s*$/, 1] if index
    end

    # Karaf saves the instance list again after cloning, and would keep the stand-in's path as the root's location
    def replace_in_instance_list(from, to)
      return unless File.exist?(instance_list)

      properties = File.read(instance_list)
      File.write(instance_list, properties.gsub(from, to)) if properties.include?(from)
    end

    def mirror(source, target, top_level: false)
      FileUtils.mkdir_p(target)
      Dir.children(source).each do |name|
        next if top_level && EXCLUDED.include?(name)

        from = File.join(source, name)
        to = File.join(target, name)
        if top_level && EMPTY_DIRECTORIES.include?(name)
          FileUtils.mkdir_p(to)
        elsif !accessible?(from)
          warn "Not cloning #{from}: the user running the specs can't read it"
        elsif File.directory?(from) && !File.symlink?(from)
          mirror(from, to)
        else
          File.symlink(from, to)
        end
      end
    rescue SystemCallError => e
      warn "Not cloning all of #{source}: #{e.message}"
    end

    def accessible?(file)
      File.readable?(file) && (!File.directory?(file) || File.executable?(file))
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(ReadableClone::CreateInstance)
