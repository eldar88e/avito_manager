module Avito
  class DashboardController < ApplicationController
    include AvitoConcerns

    before_action :set_stores, :set_account, :set_rate
    before_action :set_auto_load, only: :index
    # add_breadcrumb 'Dashboard', :store_avito_dashboard_path
    layout 'avito'

    def index
      @report = fetch_cached("report_#{@store.id}", url: 'https://api.avito.ru/autoload/v4/uploads/last_successful')
      message = @report.dig('error', 'message')
      @report = {} if message.present? # .nil? || message == 'Report not found'
      @bal    = fetch_cached("bal_#{@store.id}",
                             url: 'https://api.avito.ru/cpa/v3/balanceInfo', method: :post, payload: {})
      @balance = fetch_cached("balance_#{@store.id}",
                              url: "https://api.avito.ru/core/v1/accounts/#{@account['id']}/balance/")
      error = instance_variables[-6..].map { |var| instance_variable_get(var) }.find { |i| i['error'] }
      error_notice(error['error']['message'], :bad_gateway) if error
    end
  end
end
