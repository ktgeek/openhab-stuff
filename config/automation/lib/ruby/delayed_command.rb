# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

class DelayedCommand
  def initialize(item, command)
    @item = item
    @command = command
  end

  def execute
    @item.ensure << @command
  end
end
