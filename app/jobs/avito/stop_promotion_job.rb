# Avito::UpdatePromotionJob.perform_now(1, 1)

module Avito
  class UpdatePromotionJob < Avito::BaseApplicationJob
    queue_as :default

    def perform(**args)
      user     = User.find(args[:user_id])
      store    = user.stores.find(args[:store_id])
      avito    = initialize_avito(store)
      entities = args[:address_ids].present? ? store.addresses.where(id: args[:address_id]) : store
      entities.ads.where(promotion: true).find_each { |ad| stop_promotion(avito, ad) }
    end

    private

    def stop_promotion(avito, adv)
      url      = 'https://api.avito.ru/cpxpromo/1/remove'
      item_id  = adv.avito_id || fetch_avito_id(avito, adv)
      response = avito.connect_to(url, :post, { 'itemId' => item_id })
      msg      = "‼️ Ошибка снятия ad ##{adv.file_id} с ручного поднятия.\n#{response&.status}\n#{response&.body}"
      return TelegramService.call(adv.user, msg) unless response&.success?

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
  end
end
