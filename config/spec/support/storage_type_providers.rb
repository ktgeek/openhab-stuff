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

  # OpenHAB::OSGi is first loaded by the `require "openhab/dsl"` that the harness does right after launching Karaf, and
  # the providers are registered straight after that, so the guard has to be in place in between.
  module Launch
    def launch
      main = super
      require "openhab/dsl"
      OpenHAB::OSGi.singleton_class.prepend(RegisterService)
      main
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(StorageTypeProviders::Launch)
