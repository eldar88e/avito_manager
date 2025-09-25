require 'faraday'

class OkkiApiService
  def initialize(url, token, page = 1)
    @conn = Faraday.new(url: url) do |f|
      f.request :json
      f.response :json, content_type: /\bjson$/
      f.adapter Faraday.default_adapter
    end
    @page  = page
    @token = token
  end

  def self.call(url, token, page = 1)
    new(url, token, page).fetch_products
  end

  def fetch_products
    response = @conn.get("/api/v1/products?page=#{@page}") do |req|
      req.headers['Authorization'] = @token
    end

    response.body
  rescue StandardError => e
    Rails.logger.error e.message
    { error: e.message }
  end
end
