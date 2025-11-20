module Avito
  class UpdatePromotionStatusJob < Avito::BaseApplicationJob
    queue_as :default

    AD_TYPES = 'AdImport'.freeze
    MAX_PROMOTION = 2
    MIN_BID = 99
    UP_LIMIT_PENNY = 100

    def perform(user_id, store_id)
      user  = User.find(user_id)
      store = user.stores.active.find(store_id)
      process_store(store)
    end

    private

    def process_store(store)
      avito = initialize_avito(store)

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
      avito.connect_to(url, :post, { 'itemId' => item_id })
      adv.update(promotion: false)
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
      msg = "✅ Объявление #{adv.adable.title} поднято в ручном режиме."
      msg += "\n\nСтоимость: #{value_penny / 100} ₽\n\nhttps://www.avito.ru/#{adv.avito_id}"
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
  end
end
