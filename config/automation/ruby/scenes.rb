# frozen_string_literal: true

changed Clear_Scenes.members do |event|
  next if event.null?

  event.item.update(NULL)
end
