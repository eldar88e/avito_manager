class TelegramJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user = find_user args
    TelegramService.call(user, args[:msg])
  end
end
