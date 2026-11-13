# frozen_string_literal: true

require_relative "readable_clone"

# The harness clones the live instance, including its ConfigAdmin store, and every config there still names the file in
# production's etc/ it was loaded from (`felix.fileinstall.filename`). The harness then updates org.openhab.addons,
# org.openhab.persistence and org.openhab.ephemeris on startup, and the clone's fileinstall saves each update to the
# file the config names: production's. When the user running the specs can write those files, production's add-on list
# gets replaced by the specs' trimmed one and production uninstalls the rest. So make the clone refer only to itself,
# stop its fileinstall saving configs at all, and refuse to start if anything still points at production.
#
# The work is `ReadableClone::InstanceService.isolate_clone`, which is openhab/openhab-jruby#587 (fixes #580) as it is
# at 986cc792f. That runs when the clone is made; this file runs it on every launch, the way the PR's `cleanup_instance`
# does, so a clone made earlier (or by the gem's own copy) is covered too. Remove this file once a release with that PR
# ships, and copy the changes over again if the PR changes before then. Even then, keep it until a launch has been
# checked against hashes of production's files, since a regression here costs data, not a failing spec.
module ProductionIsolation
  # Runs on every launch, after the clone exists and before Karaf starts, so a fresh .karaf/ is covered too.
  module CleanupInstance
    private

    # The PR calls this from the harness's own `cleanup_instance`, with the userdata directory it started from. The
    # gem this runs against doesn't record that directory, so it is the one the specs are started with. It comes before
    # `super`, as in the PR: the harness's `cleanup_clone` deletes files in the clone's config store, and isolation
    # refuses a clone whose store leads to production.
    def cleanup_instance
      ReadableClone::InstanceService.isolate_clone(ENV.fetch("OPENHAB_USERDATA"), path)

      super
    end
  end
end

OpenHAB::RSpec::Karaf.prepend(ProductionIsolation::CleanupInstance)
