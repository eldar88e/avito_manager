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
  end
end
