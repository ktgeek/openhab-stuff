# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module Holidays
  CHRISTMAS = "Christmas"
  HALLOWEEN = "Halloween"
  STPATRICKS = "St.Pats"

  def self.current?(holiday)
    ::Holiday_Mode.state == holiday
  end
end
