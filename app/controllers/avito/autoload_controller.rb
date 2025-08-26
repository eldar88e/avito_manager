module Avito
  class AutoloadController < ApplicationController
    include AvitoConcerns

    before_action :ensure_turbo_stream_request, only: %i[show edit]
    before_action :set_auto_load, only: %i[show edit update]
    layout 'avito'

    def show
      render turbo_stream: turbo_stream.replace(@store, partial: '/avito/autoload/show')
    end

    def edit
      render turbo_stream: turbo_stream.replace(@store, partial: '/avito/autoload/edit')
    end

    def update
      a_params = make_params
      Avito::AutoLoadJob.perform_later(store: @store, params: a_params)
      handle_turbo
      # result = @avito.connect_to('https://api.avito.ru/autoload/v1/profile', :post, a_params)
      # if result&.status == 200
      # Rails.cache.delete("auto_load_#{@store.id}")
      #   set_auto_load
      #   msg = t 'avito.notice.upd_autoload_conf'
      #   render turbo_stream: [turbo_stream.replace(@store, partial: '/avito/autoload/show'), success_notice(msg)]
      # else
      #   error_notice t('avito.error.upd_autoload_conf')
      # end
    end

    def update_ads
      result = @avito.connect_to('https://api.avito.ru/autoload/v1/upload', :post)
      if result&.status == 200
        render turbo_stream: success_notice(t('avito.notice.upd_ads'))
      else
        error_notice(t('avito.error.upd_ads'))
      end
    end

    private

    def make_params
      enabled  = params[:store][:autoload_enabled] == '1'
      keys     = %i[upload_url report_email]
      a_params = { agreement: true, autoload_enabled: enabled,
                   schedule: [{ rate: params[:store][:rate].to_i, time_slots: filtered_params(:time_slots),
                                weekdays: filtered_params(:weekdays) }] }
      a_params.merge!(autoload_params.slice(*keys))
    end

    def filtered_params(item)
      params[:store][item].compact_blank.map(&:to_i)
    end

    def handle_turbo
      render turbo_stream: [
        turbo_stream.replace(@store, partial: '/avito/autoload/show'),
        success_notice(t('controllers.avito.autoload.update', name: @store.manager_name))
      ]
    end

    def ensure_turbo_stream_request
      redirect_to store_avito_dashboard_path unless turbo_frame_request?
    end

    def autoload_params
      params.expect(store: [:upload_url, :report_email, :autoload_enabled, :rate, { weekdays: [], time_slots: [] }])
    end
  end
end
