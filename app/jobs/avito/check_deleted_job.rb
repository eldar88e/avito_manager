module Avito
  class CheckDeletedJob < Avito::BaseApplicationJob
    queue_as :default
    PER_PAGE = 100

    def perform(**args)
      user   = find_user(args)
      stores = [args[:store] || user&.stores&.active].flatten.compact
      stores.each do |store|
        avito = AvitoService.new(store:)
        next if avito.token_status == 403

        deleted = [0]
        process_store(store, avito, deleted)
        next unless deleted[0].positive?

        TelegramService.call(user, I18n.t('avito.job.check_deleted', count: deleted[0], name: store.manager_name))
      end
      nil
    end

    private

    def process_store(store, avito, deleted)
      report_url = fetch_report_url(avito)
      return if report_url.nil?

      ads_db = store.ads.load
      page   = 0
      cache  = {}
      loop do
        url = "#{report_url}/items?page=#{page}&per_page=#{PER_PAGE}&sections=error_deleted"
        ads = cache[:"#{page}"] ||= fetch_and_parse(avito, url)
        break if ads&.dig('items').blank?

        ads['items'].each do |item|
          avito_id = item['avito_id']
          existing_ad = find_ad(avito_id, ads_db, avito)
          update_ad(avito_id, existing_ad, deleted)
        end
        page += 1
      end
    end

    def update_ad(avito_id, item, deleted)
      return unless item

      item.update(avito_id:, deleted: 1)
      deleted[0] += 1 if item.saved_changes?
    end

    def fetch_report_url(avito)
      last_report_url = 'https://api.avito.ru/autoload/v2/reports/last_completed_report'
      report          = fetch_and_parse(avito, last_report_url)
      return if report.nil?

      "https://api.avito.ru/autoload/v2/reports/#{report['report_id']}"
    end

    def find_ad(avito_id, ads_db, avito)
      existing_ad = ads_db.find_by(avito_id:)
      return existing_ad if existing_ad

      url      = "https://api.avito.ru/autoload/v2/items/ad_ids?query=#{avito_id}"
      response = fetch_and_parse(avito, url)
      return if response.nil?

      sleep rand(0.3..0.9)
      ad_id = response['items'][0]['ad_id'].to_i
      ads_db.find_by(id: ad_id)
    end
  end
end
