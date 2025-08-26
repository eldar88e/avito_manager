module Avito
  class ItemsController < ApplicationController
    include AvitoConcerns

    before_action :index_breadcrumbs, :set_status, :set_page_params
    layout 'avito'
    ALLOWED_STATUSES = %w[active blocked old removed rejected].freeze
    MIN_PER_PAGE     = 25
    MAX_PER_PAGE     = 100

    def index
      url       = "https://api.avito.ru/core/v1/items?page=#{@page}&per_page=#{@per_page}&status=#{@status}"
      @items    = fetch_and_parse url
      @end_page = fetch_end_page
    end

    private

    def fetch_end_page
      end_page_key = "store_#{@store.id}_#{@status}_end_page"
      if @items['resources'].size == @per_page && @page >= (session[end_page_key] ||= 1)
        session[end_page_key] = @page + 1
      end
      session[end_page_key] = @page if @items['resources'].size < @per_page
      session[end_page_key] || 1
    end

    def set_status
      status  = params['status']
      key     = "store_#{@store.id}_status"
      @status = session[key] = ALLOWED_STATUSES.include?(status) ? status : session[key] || 'active'
    end

    def set_page_params
      @page     = [params['page'].to_i, 1].max
      per_page  = params['per_page'].to_i
      key       = "per_page_#{@status}"
      @per_page = session[key] = per_page >= MIN_PER_PAGE ? per_page : session[key] || MAX_PER_PAGE
    end

    def index_breadcrumbs
      add_breadcrumb @store.manager_name, store_avito_dashboard_path
      add_breadcrumb 'Items', store_avito_items_path
    end
  end
end
