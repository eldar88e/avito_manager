module Avito
  class UpdatePromotionJob < Avito::BaseApplicationJob
    queue_as :default

    AD_TYPES = 'AdImport'.freeze
    MAX_PROMOTION = 2
    MIN_BID = 99
    UP_LIMIT_PENNY = 100
    MAX_MONEY = 500

    def perform(user_id, store_id)
      user       = User.find(user_id)
      store      = user.stores.active.find(store_id)
      avito      = initialize_avito(store)
      account_id = fetch_account_id(store, avito)&.dig('id')
      statistics = fetch_statistics(avito, account_id)
      TelegramService.call(user, statistics)
      (statistics['presenceSpending'] / 100) < MAX_MONEY ? process_store(store, avito) : stop_all_promotion(store, avito)
      nil
    end

    private

    def stop_all_promotion(store, avito)
      store.ads.where(promotion: true).find_each { |ad| stop_promotion(avito, ad) }
    end

    def process_store(store, avito)
      store.addresses.active.each do |address|
        ads       = address.ads.active_ads.where(adable_type: AD_TYPES)
        promo_ads = ads.where(promotion: true)
        promo_ads.each { |ad| stop_promotion(avito, ad) } if promo_ads.present?
        new_ads = (ads - promo_ads).sample(MAX_PROMOTION)
        update_promotion(avito, new_ads)
      end
    end

    def stop_promotion(avito, adv)
      url     = 'https://api.avito.ru/cpxpromo/1/remove'
      item_id = adv.avito_id || fetch_avito_id(avito, adv)
      response = avito.connect_to(url, :post, { 'itemId' => item_id })
      return unless response&.success?

      adv.update(promotion: false)
      msg = "❌ Объявление #{adv.adable.title} снято с ручного поднятия.\nАдрес: #{adv.full_address}"
      msg += "\n\nhttps://www.avito.ru/#{adv.avito_id}"
      TelegramService.call(adv.user, msg)
    end

    def update_promotion(avito, ads)
      ads.each do |adv|
        promotion = fetch_promotion(avito, adv)
        bids      = promotion['manual']['bids'].select { |b| b['compare'] == MIN_BID }
        best_min  = bids.min_by { |b| b['valuePenny'] }
        make_manual_promotion(avito, adv, best_min['valuePenny'])
      end
    end

    def make_manual_promotion(avito, adv, value_penny)
      url     = 'https://api.avito.ru/cpxpromo/1/setManual'
      item_id = adv.avito_id || fetch_avito_id(avito, adv)
      payload = { 'actionTypeID' => 5, 'bidPenny' => value_penny,
                  'itemID' => item_id, 'limitPenny' => value_penny + UP_LIMIT_PENNY }
      result = avito.connect_to(url, :post, payload)
      return unless result&.success?

      adv.update(promotion: true)
      msg = "✅ Объявление #{adv.adable.title} поднято в ручном режиме.\nАдрес: #{adv.full_address}"
      msg += "\nСтоимость: #{value_penny / 100} ₽\n\nhttps://www.avito.ru/#{adv.avito_id}"
      TelegramService.call(adv.user, msg)
    end

    def fetch_promotion(avito, adv)
      item_id = adv.avito_id || fetch_avito_id(avito, adv)
      url = "https://api.avito.ru/cpxpromo/1/getBids/#{item_id}"
      response = avito.connect_to(url, :get)
      JSON.parse(response.body)
    end

    def initialize_avito(store)
      avito = AvitoService.new(store:)
      raise StandardError, 'Failed to get token' if avito.token_status.present? && avito.token_status != 200

      avito
    end

    def fetch_account_id(store, avito)
      result = Rails.cache.fetch("account_#{store.id}", expires_in: 6.hours) do
        response = avito.connect_to('https://api.avito.ru/core/v1/accounts/self')
        next nil if response&.status != 200

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error e.message
        nil
      end
      Rails.cache.delete("account_#{store.id}") if result.nil?
      result
    end

    def fetch_statistics(avito, account_id)
      payload = {
        'dateFrom' => Time.current.to_date.to_s,
        'dateTo' => Time.current.to_date.to_s,
        'metrics' => %w[views contacts favorites presenceSpending impressions],
        'grouping' => 'day'
      }
      response = avito.connect_to("https://api.avito.ru/stats/v2/accounts/#{account_id}/items", :post, payload)
      result = JSON.parse(response.body)
      result['result']['groupings'].first['metrics'].to_h { |i| [i['slug'], i['value']] }
    end
  end
end
