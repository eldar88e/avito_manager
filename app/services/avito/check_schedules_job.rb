module Avito
  class CheckSchedulesJob < Avito::BaseApplicationJob
    queue_as :default

    def perform(**args)
      current_user = find_user args
      stores       = current_user.stores.active
      stores.each do |store|
        avito = initialize_avito(store, current_user)
        next if avito.nil?

        auto_load = fetch_and_parse(avito, 'https://api.avito.ru/autoload/v1/profile')
        next if auto_load.nil?

        check_schedules(store, auto_load, current_user)
      end

      nil
    end

    private

    def check_schedules(store, auto_load, current_user)
      weekdays  = auto_load['schedule'][0]['weekdays']
      msg       = "‼️#{store.manager_name} указанно более двух дней для автозагрузки."
      TelegramService.call(current_user, msg) if weekdays.size > 1

      time = auto_load['schedule'][0]['time_slots']
      msg  = "‼️#{store.manager_name} указано более одного временного интервала для автозагрузки."
      TelegramService.call(current_user, msg) if time.size > 1
    end

    def initialize_avito(store, user)
      avito = AvitoService.new(store:)
      return avito if avito.token_status != 403

      msg = "‼️Доступ запрещён. Возможно аккаунт #{store.manager_name} заблокирован"
      TelegramService.call(user, msg)
      nil
    end
  end
end
