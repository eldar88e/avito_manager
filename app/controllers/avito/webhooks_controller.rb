module Avito
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      data    = request.body.read
      webhook = JSON.parse(data)
      return head :ok if user_is_author?(webhook)

      process_webhook(webhook)
    rescue StandardError => e
      handle_error(e)
    end

    private

    def process_webhook(webhook)
      msg = webhook.dig('payload', 'value', 'content', 'text')
      broadcast_notify(msg)
      render json: { status: 'ok' }, status: :ok # head :ok
    end

    def user_is_author?(webhook)
      webhook.dig('payload', 'value', 'user_id') == webhook.dig('payload', 'value', 'author_id')
    end

    def handle_error(error)
      render json: { error: error.message }, status: :not_found
      broadcast_notify(error.message, 'danger')
      TelegramService.call(User.first, error.message)
    end

    def broadcast_notify(message, key = 'success')
      Turbo::StreamsChannel.broadcast_append_to(
        :notify,
        target: :notices,
        partial: '/notices/notice',
        locals: { notices: message, key: }
      )
    end
  end
end
