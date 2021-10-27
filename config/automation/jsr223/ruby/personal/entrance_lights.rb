# frozen_string_literal: true

require 'openhab'

rule "Hall Lights follow" do
  changed All_Hall_Lights.members

  run { |event| All_Hall_Lights.each { |i| i.ensure << event.state } }
end
