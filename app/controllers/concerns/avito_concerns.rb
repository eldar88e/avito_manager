module AvitoConcerns
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!, :set_store_and_check, :set_avito
    # add_breadcrumb 'Главная', :root_path
    # add_breadcrumb 'Avito', :avitos_path
  end

  private

  def fetch_and_parse(url, method = :get, payload = nil)
    response = @avito.connect_to(url, method, payload)
    return { 'error' => "Ошибка подключения к API Avito. Статус: #{response&.status}" } unless response&.success?

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    { 'error' => "Ошибка парсинга JSON: #{e.message}" }
  end

  def set_store_and_check
    set_store
    return unless @store.nil? || @store.client_id.blank? || @store.client_secret.blank?

    error_notice t('avito.error.set_store')
  end

  def set_avito
    @avito = AvitoService.new(store: @store)
    return if @avito.token_status.nil? || @avito.token_status == 200

    error_notice t('avito.error.set_avito')
  end

  def set_account
    @account = fetch_cached("account_#{@store.id}", 6.hours, url: 'https://api.avito.ru/core/v1/accounts/self')
  end

  def set_rate
    @rate = fetch_cached("rate_#{@store.id}", 1.hour, url: 'https://api.avito.ru/ratings/v1/info')
  end

  def set_auto_load
    @auto_load = fetch_cached("auto_load_#{@store.id}", 30.minutes, url: 'https://api.avito.ru/autoload/v1/profile')
  end

  def fetch_cached(key, expires_in = 5.minutes, **args)
    result = Rails.cache.fetch(key, expires_in:) do
      fetch_and_parse(args[:url], args[:method] || :get, args[:payload])
    end
    Rails.cache.delete(key) if result.is_a?(Hash) && result.key?(:error)
    result
  end

  def set_store_breadcrumbs
    # add_breadcrumb @store.manager_name, store_avito_dashboard_path
  end

  def set_stores
    cache_key = "user_#{current_user.id}_active_stores"
    @stores   = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      current_user.stores.active.select(:id, :manager_name).as_json
    end
  end
end
