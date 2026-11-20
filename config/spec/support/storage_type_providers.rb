# frozen_string_literal: true

require "openhab/rspec/karaf"

# The harness wraps each binding's storage-based type provider in a generated subclass of
# AbstractStorageBasedTypeProvider and registers it under every interface the binding's component provides. A binding
# that provides an interface of its own (zwavejs's ZwaveJSChannelTypeProvider) can't be satisfied by that subclass, and
# OSGi rejects the registration, which aborts startup. Register only the interfaces the generated class implements.
module StorageTypeProviders
  def self.implemented_names(java_class, names = Set.new)
    return names if java_class.nil?

    names << java_class.name
    java_class.interfaces.each { |interface| implemented_names(interface, names) }
    implemented_names(java_class.superclass, names)
  end

  module RegisterService
    def register_service(instance, *interfaces, **)
      return super unless instance.is_a?(org.openhab.core.thing.binding.AbstractStorageBasedTypeProvider)

      implemented = StorageTypeProviders.implemented_names(instance.class.java_class)
      super(instance, *interfaces.select { |name| implemented.include?(name.to_s) }, **)
    end
  end

  # OpenHAB::OSGi is first loaded by the `require "openhab/dsl"` in the harness's launch, which waits for the default
  # script scope to fill `$ir` first, so requiring it earlier here would race with that. The harness waits again for the
  # rule engine after loading the DSL and before it registers the providers, so guard it when that wait returns.
  module Wait
    private

    def wait(...)
      result = super
      guard_register_service
      result
    end

    def guard_register_service
      return unless defined?(OpenHAB::OSGi)
      return if OpenHAB::OSGi.singleton_class.include?(RegisterService)

      OpenHAB::OSGi.singleton_class.prepend(RegisterService)
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(StorageTypeProviders::Wait)
