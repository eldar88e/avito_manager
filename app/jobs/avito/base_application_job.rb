module Avito
  class BaseApplicationJob < ApplicationJob
    private

    def fetch_and_parse(avito, url, method = :get, payload = nil)
      response = avito.connect_to(url, method, payload)
      return if response&.status != 200

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Rails.logger.error e.message
      nil
    end

    def fetch_avito_id(avito, item)
      url      = "https://api.avito.ru/autoload/v2/items/avito_ids?query=#{item.id}"
      response = fetch_and_parse(avito, url) || {}
      avito_id = response['items']&.at(0)&.dig('avito_id')
      return unless avito_id

      item.update(avito_id: avito_id)
      avito_id
    end
  end
end
