module Avito
  class UpdatePriceJob < Avito::BaseApplicationJob
    queue_as :default

    def perform(**args)
      last_run = Run.last
      return if last_run&.status != 'finish'

      user     = find_user(args)
      game_ids = Game.where(price_updated: last_run.id)&.ids
      ads      = Ad.includes(:adable).active_ads.where(adable_type: 'Game', adable_id: game_ids)
      notify_list_game(user, game_ids)
      ads.group_by(&:store_id).each { |key, group_ads| update_price(key, group_ads, user) }
      nil
    rescue StandardError => e
      handle_error(e)
    end

    private

    def handle_error(error)
      Rails.logger.error "Error #{self.class} || #{error.message}"
      TelegramService.call(user, "Error #{self.class} || #{error.message}")
    end

    def update_price(key, group_ads, user)
      store = Store.find_by(id: key, active: true)
      return unless store

      avito = AvitoService.new(store:)
      count = group_ads.reduce(0) do |acc, adv|
        result = process_ad(store, avito, adv)
        sleep rand(0.3..0.5)
        result&.dig('result', 'success').present? ? acc + 1 : acc
      end
      notify_updated(user, count, store)
    end

    def notify_updated(user, count, store)
      msg = "Обновились цены у #{count} игр на аккаунте #{store.manager_name}"
      notify(user, msg) if count.positive?
    end

    def notify_list_game(user, game_ids)
      games = Game.where(id: game_ids).pluck(:name).map.with_index(1) { |name, index| "#{index}. `#{name}`" }
      msg   = "Игры к обновлению цен:\n#{games.join("\n")}"
      notify(user, msg) if games.size.positive?
    end

    def process_ad(store, avito, advert)
      item_id = advert.avito_id || fetch_avito_id(avito, advert)
      url     = "https://api.avito.ru/core/v1/items/#{item_id}/update_price"
      price   = GamePriceService.call(advert.adable.price_tl, store)
      fetch_and_parse(avito, url, :post, { price: })
    end

    def fetch_avito_id(avito, item)
      url      = "https://api.avito.ru/autoload/v2/items/avito_ids?query=#{item.id}"
      response = fetch_and_parse(avito, url) || {}
      item_id  = response['items']&.at(0)&.dig('avito_id')
      return unless item_id

      item.update(avito_id: item_id)
      item_id
    end
  end
end
