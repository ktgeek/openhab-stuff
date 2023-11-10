# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module Homeseer
  # This is how to map actions to scenes for a the homeseer switch with native zwave support
  # [Paddle Direction]
  # 1.n = Top
  # 2.n = Bottom

  # [Action]
  # n.0 = 1 Click
  # n.1 = Release
  # n.2 = Hold
  # n.3 = 2 Clicks
  # n.4 = 3 Clicks
  # n.5 = 4 Clicks
  # n.6 = 5 Clicks
  #
  # However, using zwavejs-ui, up and down are seperate scene things to pull from, so we just use the scene number

  PADDLE_UP_CLICK = 1.0
  PADDLE_UP_RELEASE = 1.1
  PADDLE_UP_HOLD = 1.2
  PADDLE_UP_TWO_CLICKS = 1.3
  PADDLE_UP_THREE_CLICKS = 1.4
  PADDLE_UP_FOUR_CLICKS = 1.5
  PADDLE_UP_FIVE_CLICKS = 1.6

  PADDLE_DOWN_CLICK = 2.0
  PADDLE_DOWN_RELEASE = 2.1
  PADDLE_DOWN_HOLD = 2.2
  PADDLE_DOWN_TWO_CLICKS = 2.3
  PADDLE_DOWN_THREE_CLICKS = 2.4
  PADDLE_DOWN_FOUR_CLICKS = 2.5
  PADDLE_DOWN_FIVE_CLICKS = 2.6

  PADDLE_CLICK = 0
  PADDLE_RELEASE = 1
  PADDLE_HOLD = 2
  PADDLE_TWO_CLICKS = 3
  PADDLE_THREE_CLICKS = 4
  PADDLE_FOUR_CLICKS = 5
  PADDLE_FIVE_CLICKS = 6

  module LedColor
    OFF = 0
    RED = 1
    GREEN = 2
    BLUE = 3
    MAGENTA = 4
    YELLOW = 5
    CYAN = 6
    WHITE = 7
  end
end
