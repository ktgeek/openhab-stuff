# frozen_string_literal: true

require "awtrix"
require "tv_notification"

# A message shown on the TVs that are on and on every clock, for the rules that announce a door or a lock.
module Announce
  def self.show(message:, icon:, color: nil, avoid_appletv: false)
    TvNotification.notify(message:, avoid_appletv:)
    Awtrix.all_clocks.show_custom_notification(message:, icon:, color:)
  end
end
