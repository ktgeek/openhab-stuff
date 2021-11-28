# frozen_string_literal: true

# These are monkey patches I'm using until pull requests are accepted

logger.warn("Loading script #{__FILE__}")

class OpenHAB::DSL::Items::GenericItem
  def linked_thing
    all_linked_things.first
  end

  def all_linked_things
    registry = OpenHAB::Core::OSGI.service('org.openhab.core.thing.link.ItemChannelLinkRegistry')
    channels = registry.get_bound_channels(name).to_a
    channels.map(&:thing_uid).uniq.map { |tuid| things[tuid] }
  end
end

class OpenHAB::DSL::Things::Things
  def [](uid)
    uid = org.openhab.core.thing.ThingUID.new(*uid.split(':')) unless uid.is_a?(org.openhab.core.thing.ThingUID)
    thing = $things.get(uid) # rubocop: disable Style/GlobalVars
    return unless thing

    logger.trace("Retrieved Thing(#{thing}) from registry for uid: #{uid}")
    Thing.new(thing)
  end
end
