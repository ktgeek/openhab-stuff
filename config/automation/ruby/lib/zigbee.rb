# frozen_string_literal: true

logger.info("Loading script #{__FILE__}")

module Zigbee
  module Events
    SINGLE_TAP = "single"
    DOUBLE_TAP = "double"
    TRIPLE_TAP = "triple"
    QUADRUPLE_TAP = "quadruple"
    QUINTUPLE_TAP = "quintuple"
    HELD = "held"
    RELEASE = "release"
  end

  module Remote
    DEVICE_MODEL_IDS = [
      "Wireless switch with 4 buttons",
      "Smart button"
    ].to_set

    class << self
      def event(name, &block)
        id = OpenHAB::DSL::Rules::NameInference.infer_rule_id_from_block(block)
        script = block.source
        binding = block.binding
        OpenHAB::DSL.rule(name, id:, script:, binding:) do
          event "openhab/channels/*/triggered", types: "ChannelTriggeredEvent"

          run do |event|
            return unless DEVICE_MODEL_IDS.include?(event.thing.properties["modelId"])

            label = event.thing.label
            yield(label, event.event)
          end
        end
      end
    end
  end
end
