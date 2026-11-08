# frozen_string_literal: true

# The harness registers its mock persistence service as "default" and makes that the default persistence service, but
# it runs against the live conf directory, whose services/runtime.cfg re-applies production's default (timescaledb)
# afterwards. Every default-service lookup in a rule then logged a warning and found nothing, so set it again once
# startup has settled. Required after thing_initialization so that this hook runs after its wait.
RSpec.configure do |config|
  config.before(:suite) do
    admin = OpenHAB::OSGi.service("org.osgi.service.cm.ConfigurationAdmin")
    cfg = admin.get_configuration("org.openhab.persistence", nil)
    props = cfg.properties || java.util.Hashtable.new
    props.put("default", "default")
    cfg.update(props)
  end
end
