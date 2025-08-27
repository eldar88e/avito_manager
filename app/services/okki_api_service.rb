require 'faraday'

class OkkiApiService
  def initialize(url, token, params = nil)
    @conn = Faraday.new(url: url) do |f|
      f.request :json
      f.response :json, content_type: /\bjson$/
      f.adapter Faraday.default_adapter
    end
    @params = params
    @token = token
  end

  def self.call(url, params = nil)
    new(url, params).fetch_products
  end

  def fetch_products
    response = @conn.get("/api/v1/products#{@params}") do |req|
      req.headers['Authorization'] = @token
    end

    response.body
  rescue StandardError => e
    Rails.logger.error e.message
    { error: e.message }
  end
end
