class ImportProductsJob < ApplicationJob
  queue_as :default
  KEYS   = %w[external_id title].freeze
  COLORS = %w[
    Белый Бежевый Коричневый Чёрный Серый Золотой Серебристый Зелёный Синий Оранжевый Красный Розовый
    Жёлтый Бирюзовый Бордовый Голубой Фиолетовый Разноцветный Прозрачный
  ].freeze

  def perform(**args)
    user   = find_user(args)
    result = fetch_products(user)
    run_id = Run.last_id
    count  = [0, 0]
    Run.status = :processing
    result['pagination']['total_pages'].times do |page|
      page += 1
      result = page == 1 ? result : fetch_products(user, page)
      result['products'].each do |product|
        next if product['extra']['width'].blank? || product['price'].blank?

        process_product(user, product, run_id, count)
      end
    end
    user.ad_imports.where(deleted: false).where.not(touched_run_id: run_id)
        .update_all(deleted: true, updated_at: Time.current)
    Run.finish
    send_notify(user, count[1], count[0], result['pagination']['total_count'])
    # raise "Страниц #{result['pagination']['total_pages']} обработано 1" if result['pagination']['total_pages'] > 1

    count[1]
  rescue StandardError => e
    handle_error(user, e)
  end

  private

  def handle_error(user, error)
    msg = "Error #{self.class} || #{error.message}"
    Rails.logger.error(msg)
    broadcast_notify(msg, 'danger')
    TelegramService.call(user, msg)
    0
  end

  def send_notify(user, created, edited, size)
    msg = "✅ Обновлено #{size} объявлений."
    msg += "\n#{I18n.t('jobs.top_games.add', count: created)}" if created.positive?
    msg += "\n#{I18n.t('jobs.top_games.price', count: edited)}" if edited.positive?
    broadcast_notify(msg)
    TelegramService.call(user, msg)
  end

  def process_product(user, row, run_id, count)
    row[:images] = { first: row.delete('first_image'), other: row.delete('images') }

    color                                    = row['extra']['color']
    row['extra']['color']                    = COLORS.include?(color) ? color : 'Другой'
    row['extra']['color_name']               = color if row['extra']['color'] == 'Другой'
    row['extra']['condition_sleeping_place'] = 'Ровное' if row['extra']['sleeping_place'].present?
    row['extra']['mechanism_condition']      = 'Всё в порядке' if row['extra']['folding_mechanism'].present? && row['extra']['folding_mechanism'] != 'Без механизма'
    row['extra']['sofa_corner']              = 'Универсальный' if row['extra']['furniture_shape'] == 'Угловой'
    row['extra']['cabinet_type']             = 'Прикроватные тумбы' if row['category'] == 'Тумбы'
    row['extra']['material']                 = 'МДФ|Дерево' if row['category'] == 'Тумбы'
    row['extra']['purpose']                  = 'Гостиная' if row['category'] == 'Диваны'
    row['extra']['purpose']                  = 'Гостиная|Детская|Кухня|Офис|Кафе и ресторан' if row['category'] == 'Мини-Диваны'

    add_attributes_bed(row) if row['category'] == 'Кровати'

    row[:md5_hash]       = md5_hash(row.slice(*KEYS).merge(row['extra']))
    row[:touched_run_id] = run_id
    result = update_product(user, row, count)
    return if result

    row[:run_id] = run_id
    user.ad_imports.create(row) && count[1] += 1
  end

  def update_product(user, row, edited)
    advert = user.ad_imports.find_by(external_id: row['external_id'].to_s)
    return if advert.nil?

    if advert.md5_hash != row[:md5_hash]
      row[:price_updated] = row[:touched_run_id]
      edited[0] += 1
    end
    advert.update(row)
  end

  def fetch_products(user, page = 1)
    url   = user.settings.fetch_value(:okki_api_url)
    token = user.settings.fetch_value(:okki_api_token)
    OkkiApiService.call(url, token, page)
  end

  def md5_hash(hash)
    str = hash.values.join
    Digest::MD5.hexdigest(str)
  end

  def add_attributes_bed(row)
    row['extra']['length']              = row['extra']['depth']
    row['extra']['furniture_type']      = 'Двуспальная' # TODO: добавить односпальная
    row['extra']['furniture_frame']     = 'Дерево|ДСП|С обивкой'
    row['extra']['SleepingPlaceWidth']  = build_sleeping_place(row['extra']['width'].to_i)
    row['extra']['SleepingPlaceLength'] = 200
  end

  def build_sleeping_place(width)
    return if width.zero?

    [200, 180, 160, 140, 120, 100, 90].find { |size| width > size - 10 }
  end
end
