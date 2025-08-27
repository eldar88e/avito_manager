module Avito
  class SettingsController < ApplicationController
    include AvitoConcerns

    before_action :set_webhook_url
    before_action :set_stores, only: [:index]
    layout 'avito'

    def index
      subscriptions_url = 'https://api.avito.ru/messenger/v1/subscriptions'
      @subscriptions    = fetch_and_parse(subscriptions_url, :post, {})['subscriptions']
    end

    def update
      url =
        if params[:subscription_del]
          'https://api.avito.ru/messenger/v1/webhook/unsubscribe'
        else
          'https://api.avito.ru/messenger/v3/webhook'
        end
      result = fetch_and_parse(url, :post, { url: @webhook_url })
      return error_notice(t('controllers.avito.settings.update.error')) unless result['ok']

      flash[:notice] = t('controllers.avito.settings.update.success')
      redirect_to "/stores/#{@store.id}/avito/webhooks/receive"
    end

    private

    def set_webhook_url
      @webhook_url = "https://#{ENV.fetch('HOST')}/stores/#{@store.id}/avito/webhooks/receive"
    end
  end
end
