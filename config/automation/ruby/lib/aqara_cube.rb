# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module AqaraCube
  module Action
    %w[shake throw wakeup fall tap slide flip180 flip90 rotate_left rotate_right].each do |w|
      const_set(w.upcase, w)
    end
  end
end
