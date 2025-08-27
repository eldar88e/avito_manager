require 'telegram/bot'

class TelegramService
  MESSAGE_LIMIT = 4_090

  def initialize(user, message)
    @message   = message
    @chat_id   = user.settings.fetch_value(:tg_chat_ids)
    @bot_token = user.settings.fetch_value(:tg_token)
  end

  def self.call(user, message)
    return Rails.logger.error("User not specified for #{self.class}") if user.nil?

    new(user, message).report
  end

  def report
    tg_send if @message.present? && credential_exists?
  end

  private

  def credential_exists?
    result = @chat_id.present? && @bot_token.present?
    Rails.logger.error 'Telegram chat ID or bot token not set!' unless result
    result
  end

  def escape(text)
    text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~>#+=|{}.!])/, '\\\\\1') # delete `
  end

  def tg_send
    message_count = (@message.size / MESSAGE_LIMIT) + 1
    @message      = "‼️Dev\n#{@message}" if Rails.env.development?
    message_count.times { handle_send_msg }
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def handle_send_msg
    text_part = next_text_part
    [@chat_id.to_s.split(',')].flatten.each { |user_id| send_bot(user_id, text_part) }
  end

  def send_bot(user_id, text_part)
    Telegram::Bot::Client.run(@bot_token) do |bot|
      bot.api.send_message(chat_id: user_id, text: escape(text_part), parse_mode: 'MarkdownV2')
    end
  end

  def next_text_part
    part = @message[0...MESSAGE_LIMIT]
    @message = @message[MESSAGE_LIMIT..] || ''
    part
  end
end
