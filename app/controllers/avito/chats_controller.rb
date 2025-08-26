module Avito
  class ChatsController < ApplicationController
    include AvitoConcerns

    before_action :set_account, only: %i[index show create]
    before_action :set_stores, :set_store_breadcrumbs, only: %i[index show create]
    layout 'avito'
    LIMIT = 30

    def index
      @page     = params[:page].to_i
      offset    = @page * LIMIT
      url_chats = "https://api.avito.ru/messenger/v2/accounts/#{@account['id']}/chats?limit=#{LIMIT}&offset=#{offset}"
      response  = fetch_and_parse(url_chats)
      return error_notice(response[:error]) if response[:error]

      @chats = response['chats']
      set_cache_end_page
    end

    def show
      @chat_id = params[:id].presence
      response = fetch_and_parse(msg_url)
      return error_notice(response[:error]) if response[:error]

      @messages = response['messages']&.reverse || []
      Rails.cache.write(@chat_id, @messages, expires_in: 1.hour)
      render turbo_stream: turbo_stream.replace(:chats, partial: 'avito/chats/messages')

      # TODO: post request for read chat
      # url = "https://api.avito.ru/messenger/v1/accounts/#{@account['id']}/chats/#{@chat_id}/read"
      # fetch_and_parse(url, :post)
    end

    def create
      @chat_id = params[:chat_id]
      url      = msg_url(1)
      payload  = { message: { text: params[:msg] }, type: 'text' }
      fetch_and_parse(url, :post, payload)
      message = formit_msg
      @messages = Rails.cache.read(@chat_id, @messages)
      render turbo_stream: [
        turbo_stream.append(:messages, partial: '/avito/chats/message', locals: { message: })
        # TODO: Сделать scroll down и очищение input после отправки сообщения
      ]
    end

    private

    def msg_url(version = 3)
      "https://api.avito.ru/messenger/v#{version}/accounts/#{@account['id']}/chats/#{@chat_id}/messages"
    end

    def formit_msg
      {
        'author_id' => @account['id'],
        'created' => Time.current.to_i,
        'content' => { 'text' => params[:msg] },
        'isRead' => false,
        'type' => 'text'
      }
    end

    def set_cache_end_page
      cache_key    = "chat_#{@store.id}_end_page"
      current_page = @chats.size == LIMIT ? @page + 1 : @page
      @end_page    = Rails.cache.fetch(cache_key, expires_in: 24.hours) { current_page }

      return unless @end_page < current_page && @chats.size == LIMIT

      Rails.cache.write(cache_key, current_page, expires_in: 24.hours)
      @end_page = current_page
    end
  end
end
