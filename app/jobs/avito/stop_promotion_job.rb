# Avito::StopPromotionJob.perform_now(user_id: 1, store_id: 1)

module Avito
  class StopPromotionJob < Avito::BaseApplicationJob
    queue_as :default

    def perform(**args)
      user     = User.find(args[:user_id])
      store    = user.stores.find(args[:store_id])
      avito    = initialize_avito(store)
      entities = args[:address_ids].present? ? store.addresses.where(id: args[:address_id]) : store
      entities.ads.where(promotion: true).find_each { |ad| stop_promotion(avito, ad) }
    ensure
      msg = "🛑 Продвижение по ручной ставке остановлено.\nВ продвижении: #{store.ads.where(promotion: true).size}"
      TelegramService.call(store.user, msg)
    end

    private

    def stop_promotion(avito, adv)
      url      = 'https://api.avito.ru/cpxpromo/1/remove'
      item_id  = adv.avito_id || fetch_avito_id(avito, adv)
      response = avito.connect_to(url, :post, { 'itemId' => item_id })
      return send_error(adv, response) unless response&.success?

      adv.update(promotion: false)
      msg = "❌ Объявление #{adv.adable.title} снято с ручного поднятия.\nАдрес: #{adv.full_address}"
      msg += "\n\nhttps://www.avito.ru/#{adv.avito_id}"
      TelegramService.call(adv.user, msg)
    end

    def initialize_avito(store)
      avito = AvitoService.new(store:)
      raise StandardError, 'Failed to get token' if avito.token_status.present? && avito.token_status != 200

      avito
    end

    def send_error(adv, response)
      body = response&.body.to_s.dup.force_encoding('UTF-8')
      msg  = "‼️ Ошибка снятия объявления #{adv.file_id} с ручного поднятия."
      msg += "\nStatus: #{response&.status}\nBody: #{body}"
      msg += "\nhttps://www.avito.ru/#{adv.avito_id}"
      TelegramService.call(adv.user, msg)
    end
  end
end
