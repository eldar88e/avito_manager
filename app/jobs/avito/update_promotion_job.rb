# Avito::UpdatePromotionJob.perform_now(1, 1)

module Avito
  class UpdatePromotionJob < Avito::BaseApplicationJob
    queue_as :default

    AD_TYPES = 'AdImport'.freeze
    MAX_PROMOTION = 2
    MIN_BID = 99
    MIN_LIMIT_PENNY = 5000
    UP_LIMIT_PENNY = 100
    PAYLOAD = {
      'dateFrom' => Time.current.to_date.to_s,
      'dateTo' => Time.current.to_date.to_s,
      'metrics' => %w[views contacts favorites presenceSpending impressions],
      'grouping' => 'day'
    }.freeze

    def perform(user_id, store_id, **args)
      max_money  = args[:max_money] || Setting.all_cached[:max_money].to_i
      user       = User.find(user_id)
      store      = user.stores.active.find(store_id)
      avito      = initialize_avito(store)
      account_id = fetch_account_id(store, avito)&.dig('id')
      statistic  = fetch_statistics(avito, account_id)
      send_telegram_msg(store, statistic, max_money)
      if (statistic['presenceSpending'] / 100) < max_money
        process_store(store, avito, args[:address_ids])
      else
        stop_all_promotion(store, avito)
      end
      msg = "✅ Ручное поднятие завершено.\nВ продвижении: #{store.ads.where(promotion: true).size}"
      TelegramService.call(store.user, msg)
    end

    private

    def send_telegram_msg(store, statistic, max_money)
      msg = "Статистика по аккаунту #{store.manager_name}:\n"
      msg += "Лимит на продвижению на сегодня: #{max_money}₽\n"
      statistic['presenceSpending'] = "#{(statistic['presenceSpending'] / 100).round(2)}₽"
      msg += statistic.map { |key, value| "#{I18n.t("avito.statistics.#{key}")}: #{value}" }.join("\n")
      TelegramService.call(store.user, msg)
    end

    def stop_all_promotion(store, avito)
      store.ads.where(promotion: true).find_each { |ad| stop_promotion(avito, ad) }
    end

    def process_store(store, avito, address_ids = [])
      store.addresses.active.each do |address|
        next if address_ids.present? && address_ids.exclude?(address.id)

        ads       = find_ads(address)
        promo_ads = ads.where(promotion: true)
        promo_ads.each { |ad| stop_promotion(avito, ad) } if promo_ads.present?
        available_ads = ads - promo_ads
        current_ads   = build_current_ads(available_ads, address)
        update_promotion(avito, current_ads)
        add_to_skip(address.id, current_ads.map(&:id))
      end
    end

    def stop_promotion(avito, adv)
      url      = 'https://api.avito.ru/cpxpromo/1/remove'
      item_id  = adv.avito_id || fetch_avito_id(avito, adv)
      response = avito.connect_to(url, :post, { 'itemId' => item_id })
      msg      = "‼️ Ошибка снятия ad ##{adv.file_id} с ручного поднятия.\n#{response&.status}\n#{response&.body}"
      return TelegramService.call(adv.user, msg) unless response&.success?

      adv.update(promotion: false)
      msg = "❌ Объявление #{adv.adable.title} снято с ручного поднятия.\nАдрес: #{adv.full_address}"
      msg += "\n\nhttps://www.avito.ru/#{adv.avito_id}"
      # TelegramService.call(adv.user, msg)
    end

    def update_promotion(avito, ads)
      ads.each do |adv|
        promotion = fetch_promotion(avito, adv)
        bids      = promotion['manual']['bids'].select { |b| b['compare'] == MIN_BID }
        best_min  = build_best_min(bids, promotion)
        make_manual_promotion(avito, adv, best_min['valuePenny'])
      end
    end

    def build_best_min(bids, promotion)
      if bids.present?
        bids.min_by { |b| b['valuePenny'] }
      else
        promotion['manual']['bids'].max_by { |b| b['compare'] }
      end
    end

    def make_manual_promotion(avito, adv, value_penny)
      url     = 'https://api.avito.ru/cpxpromo/1/setManual'
      item_id = adv.avito_id || fetch_avito_id(avito, adv)
      payload = { 'actionTypeID' => 5, 'bidPenny' => value_penny,
                  'itemID' => item_id, 'limitPenny' => [value_penny + UP_LIMIT_PENNY, MIN_LIMIT_PENNY].max }
      result = avito.connect_to(url, :post, payload)
      return unless result&.success?

      adv.update(promotion: true)
      msg = "✅ Объявление #{adv.adable.title} поднято в ручном режиме.\nАдрес: #{adv.full_address}"
      msg += "\nСтоимость: #{value_penny / 100} ₽\n\nhttps://www.avito.ru/#{adv.avito_id}"
      # TelegramService.call(adv.user, msg)
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
      Rails.cache.fetch("statistics_#{account_id}", expires_in: 2.minutes) do
        response = avito.connect_to("https://api.avito.ru/stats/v2/accounts/#{account_id}/items", :post, PAYLOAD)
        result   = JSON.parse(response.body)
        result['result']['groupings'].first['metrics'].to_h { |i| [i['slug'], i['value']] }
      end
    end

    def find_ads(address)
      address.ads
             .active_ads
             .joins("INNER JOIN ad_imports ON ads.adable_id = ad_imports.id AND ads.adable_type = 'AdImport'")
             .where(extra: nil)
             .where.not(ad_imports: { category: 'Тумбы' })
    end

    def skipped_ads(address_id)
      Rails.cache.fetch("promotion_skip_#{address_id}", expires_in: 10.minutes) { [] }
    end

    def add_to_skip(address_id, ids)
      key = "promotion_skip_#{address_id}"
      current = Rails.cache.read(key) || []
      Rails.cache.write(key, (current + ids).uniq)
    end

    def clear_skip_cache(address_id)
      Rails.cache.delete("promotion_skip_#{address_id}")
    end

    def build_current_ads(ads, address)
      skip_ids = skipped_ads(address.id)
      new_ads  = ads.reject { |ad| skip_ids.include?(ad.id) }
      if new_ads.blank? || new_ads.size < MAX_PROMOTION
        clear_skip_cache(address.id)
        new_ads = ads
      end
      new_ads.sample(MAX_PROMOTION)
    end
  end
end
