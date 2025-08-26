module Avito
  class AutoLoadJob < Avito::BaseApplicationJob
    queue_as :default

    def perform(**args)
      params = args[:params]
      avito  = args[:avito] || AvitoService.new(store: args[:store])
      return if avito.token_status == 403

      result = avito.connect_to('https://api.avito.ru/autoload/v1/profile', :post, params)
      return broadcast_notify(I18n.t('avito.error.upd_autoload_conf'), 'danger') unless result&.status == 200

      Rails.cache.delete("auto_load_#{args[:store].id}")
      broadcast_notify(I18n.t('avito.notice.upd_autoload_conf'))
    end
  end
end
