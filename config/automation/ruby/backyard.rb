# frozen_string_literal: true

require "zwave"

updated(Kitchen_Backyard_Lights_Scene_1, to: ZWave::PADDLE_CLICK) { Backyard_Lights_Power.ensure.command(ON) }

updated(Kitchen_Backyard_Lights_Scene_2, to: ZWave::PADDLE_CLICK) { Backyard_Lights_Power.ensure.command(OFF) }
