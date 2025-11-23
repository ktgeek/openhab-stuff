# frozen_string_literal: true

module TvNotification
  CONFIGURATION = [
    {
      tv_power: ::FamilyRoom_TV_Power,
      receiver_input: ::FamilyRoom_Receiver_Input_Source,
      toast: ::FamilyRoom_TV_Toast,
      appletv_input: 17
    },
    {
      tv_power: ::Basement_TV_Power,
      receiver_input: ::Basement_Receiver_Input_Source,
      toast: ::Basement_TV_Toast,
      appletv_input: 17
    }
  ].freeze

  # Send a notification to the TVs that are on, if avoid_appletv is true, skip it. avoid_appletv is useful for items
  # that HomeKit already sends notifications on the AppleTV.
  def self.notify(message:, only: nil, avoid_appletv: false)
    notify_list = CONFIGURATION.filter_map do |config|
      next if only && config[:toast] != only
      next unless config[:tv_power].on?
      next if avoid_appletv && config[:receiver_input].state.to_i == config[:appletv_input]

      config[:toast]
    end

    notify_list.command(message) unless notify_list.empty?
  end
end
