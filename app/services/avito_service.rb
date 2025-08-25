require 'faraday'

class AvitoService
  AVITO_TOKEN_URL = 'https://api.avito.ru/token'.freeze

  def initialize(**args)
    @store         = args[:store]
    @client_id     = @store.client_id
    @client_secret = @store.client_secret
    @token_status  = nil
    @token         = fetch_token
    @headers       = { 'Authorization' => "Bearer #{@token}", 'Content-Type' => 'application/json' }
  end

  attr_reader :token_status

  def connect_to(url, method = :get, payload = nil, **args)
    return if @token.blank? && args[:headers].blank?

    send_request(url, method, payload, **args)
  rescue StandardError => e
    Rails.logger.error e.message
    nil
  end

  private

  def exist_credentials?
    result = @client_id.present? && @client_secret.present?
    Rails.logger.error "Not set client_id & client_secret for #{@store.manager_name}" unless result
    result
  end

  def send_request(url, method, payload, **args)
    request    = method == :get || args[:url_encoded] ? :url_encoded : :json
    connection = Faraday.new(url:) do |faraday|
      faraday.request request
      faraday.response :logger if Rails.env.development?
      faraday.adapter Faraday.default_adapter
    end

    connection.send(method) do |req|
      req.headers = args[:headers] || @headers
      req.body    = args[:form] ? payload : payload.to_json if payload
    end
  end

  def fetch_token
    cache_key = "store_#{@store.id}_avito_token"
    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      last_token = @store.avito_tokens.latest_valid.first
      last_token&.access_token || refresh_token
    end
  end

  def refresh_token
    return unless exist_credentials?

    payload = URI.encode_www_form({ grant_type: 'client_credentials',
                                    client_id: @client_id,
                                    client_secret: @client_secret })
    headers  = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    params   = { headers:, form: true, url_encoded: true }
    response = connect_to(AVITO_TOKEN_URL, :post, payload, **params)
    return log_bad_token(response) unless response.success?

    parse_token(response)
  end

  def parse_token(response)
    token_info = JSON.parse(response.body)
    @store.avito_tokens.create token_info
    token_info['access_token']
  end

  def log_bad_token(response)
    msg = "Failed to get token! Status: (#{response.status}), Account: #{@store.manager_name}, Error: #{response.body}"
    Rails.logger.error msg
    @token_status = response.status
    nil
  end
end
