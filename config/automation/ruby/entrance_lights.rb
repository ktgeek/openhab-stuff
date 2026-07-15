# frozen_string_literal: true

require "sun_status"

def within_entrance_lights_window?
  Time.now.between?((Date.today.weekend? ? "9am" : "5:35am").."10:30pm")
end

rule "when its darks enough we think the sun is down" do
  changed Sun_Status, to: SunStatus::DOWN

  run do
    Front_Yard_Lights.members.ensure.on
    All_Hall_Lights.members.ensure.on if Time.now > LocalTime.parse("9am")
  end

  only_if { Entrance_IgnoreLuminance_Switch.off? && within_entrance_lights_window? }
end

rule "when its bright enough we think the sun is up" do
  changed Sun_Status, to: SunStatus::UP

  run do
    Front_Yard_Lights.members.ensure.off
    Front_Yard_Outdoor_Decorations_Switch.ensure.off unless Holiday_Mode.state.blank?
    All_Hall_Lights.members.ensure.off
  end

  only_if { Entrance_IgnoreLuminance_Switch.off? && within_entrance_lights_window? }
end
