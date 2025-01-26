# frozen_string_literal: true

require "zwave"

BACKYARD_LIGHT_SWITCHES = [Kitchen_Backyard_Lights_Switch.thing, FamilyRoom_Backyard_Lights_Switch.thing].freeze

channel("scene_1", thing: BACKYARD_LIGHT_SWITCHES, triggered: ZWave::PADDLE_CLICK) { Backyard_Lights_Power.ensure.on }

channel("scene_2", thing: BACKYARD_LIGHT_SWITCHES, triggered: ZWave::PADDLE_CLICK) { Backyard_Lights_Power.ensure.off }
