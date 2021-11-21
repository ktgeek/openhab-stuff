# frozen_string_literal: true

# These are monkey patches I'm using until pull requests are accepted

logger.warn("Loading script #{__FILE__}")

class OpenHAB::DSL::Items::GenericItem
  def linked_thing
    all_linked_things.first
  end

  def all_linked_things
    registry = OpenHAB::Core::OSGI.service('org.openhab.core.thing.link.ItemChannelLinkRegistry')
    channels = registry.bound_channels(name).to_a
    channels.map(&:thing_uid).uniq.map { |tuid| things[tuid] }
  end
end
