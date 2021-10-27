# frozen_string_literal: true

require 'openhab'

rule "Backyard lights follow" do
  changed Backyard_Lights.members

  run { |event| Backyard_Lights.each { |i| i.ensure << event.state } }
end
