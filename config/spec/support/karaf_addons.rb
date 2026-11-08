# frozen_string_literal: true

require "openhab/rspec/karaf"

# The harness clones the live instance into .karaf/ once and reuses it, along with production's addon settings. At
# startup Karaf is asked to install all of them in one request, and that request fails as a whole: the jinja
# transformation can't resolve javassist in the harness's trimmed-down runtime. So no addon was ever installed and every
# run logged resolver errors. Keep only the addons the specs need instead. The clone's settings are rebuilt from
# production's on every launch, so editing ALLOWED always takes effect.
module KarafAddons
  # Addon category => the entries to keep. Every other entry, and every category not listed, is dropped.
  ALLOWED = { "binding" => %w[bluetooth homeassistant mqtt zwavejs] }.freeze

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

  # Add-ons production runs from jars rather than the addons kar: the AWTRIX NG build of the Awtrix3 add-on (hand
  # installed until its PR merges) and the esphome marketplace add-on. The harness only deploys openhab-addons-*.kar
  # from the addons directory and deletes the clone's marketplace/, so neither would load. Their thing types are what
  # the specs need. The jars are copied into a private directory that the clone's fileinstall watches instead.
  EXTRA_JARS = [
    "/usr/share/openhab/addons/org.openhab.binding.mqtt.awtrixlight-*.jar",
    "#{ENV.fetch('OPENHAB_USERDATA', nil)}/marketplace/bundles/*/no.seime.openhab.binding.esphome-*.jar",
    # esphome imports javax.validation.constraints, which production gets from the REST API's swagger feature, one of
    # the things the harness's trimmed runtime base drops
    "/usr/share/openhab/runtime/system/jakarta/validation/jakarta.validation-api/2.0.2/jakarta.validation-api-2.0.2.jar"
  ].freeze

  # esphome isn't under any tree the harness blocks, so without this its real handler factory and mDNS discovery
  # would start and talk to the devices. The other jars are in org.openhab.binding, which is already blocked.
  BLOCKED_BUNDLES = %w[no.seime.openhab.binding.esphome].freeze

  # Runs on every launch, after the clone exists and before Karaf starts, so a fresh .karaf/ is covered too.
  module CleanupInstance
    # Production's file and the clone's, relative to each instance's userdata directory
    SETTINGS_FILES = %w[etc/org.openhab.addons.cfg config/org/openhab/addons.config].freeze

    private

    def cleanup_instance
      super

      rewrite_addon_settings
      add_base_features
      deploy_extra_jars
    end

    def blocked_bundle?(bundle)
      super || BLOCKED_BUNDLES.include?(bundle.symbolic_name)
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

    def deploy_extra_jars
      deploy_dir = File.join(path, "spec-addons")
      FileUtils.rm_rf(deploy_dir)
      FileUtils.mkdir_p(deploy_dir)
      EXTRA_JARS.each do |pattern|
        jars = Dir.glob(pattern)
        warn "No jar matches #{pattern}; its things won't have a thing type in the specs" if jars.empty?
        FileUtils.cp(jars, deploy_dir)
      end

      point_fileinstall_at(deploy_dir)
    end

    # The harness limits the filter to openhab-addons-*.kar on every launch, so this has to run after it
    def point_fileinstall_at(deploy_dir)
      file = File.join(path, "etc/org.apache.felix.fileinstall-deploy.cfg")
      config = File.read(file)
      updated = config.sub(/^(felix\.fileinstall\.dir\s+=)[^\n]+$/) { "#{Regexp.last_match(1)} #{deploy_dir}" }
                      .sub(/^(felix\.fileinstall\.filter\s+=)[^\n]+$/) { "#{Regexp.last_match(1)} .*\\.jar" }
      raise "no fileinstall dir or filter to rewrite in #{file}" if updated == config

      File.write(file, updated)
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(KarafAddons::CleanupInstance)
