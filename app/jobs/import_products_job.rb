class ImportProductsJob < ApplicationJob
  queue_as :default
  KEYS = %w[id name].freeze

  def perform(**args)
    products = fetch_products(args[:user])['products']
    run_id   = 1 # Run.last_id
    count  = [0, 0]
    products.each { |game| process_game(game, run_id, count) }
    Game.where(deleted: 0).where.not(touched_run_id: run_id).update_all(deleted: 1, updated_at: Time.current)
    # Run.finish
    send_notify(args[:user], count[1], count[0], games.size)
    count[1]
  rescue StandardError => e
    handle_error(args[:user], e)
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
    msg = "✅ Обновлено ТОП #{size} игр."
    msg += "\n#{I18n.t('jobs.top_games.add', count: created)}" if created.positive?
    msg += "\n#{I18n.t('jobs.top_games.price', count: edited)}" if edited.positive?
    broadcast_notify(msg)
    TelegramService.call(user, msg)
  end

  def process_game(row, run_id, count)
    filtered_row         = row.slice(*KEYS)
    row[:md5_hash]       = md5_hash(filtered_row)
    row[:touched_run_id] = run_id
    row[:deleted]        = 0
    result               = update_product(row, count)
    return if result

    row[:run_id] = run_id
    AdImport.create(row) && count[1] += 1
  end

  def update_product(row, edited)
    advert = AdImport.find_by(external_id: row[:id])
    return if advert.nil?

    if advert.md5_hash != row[:md5_hash]
      row[:price_updated] = row[:touched_run_id]
      edited[0] += 1
    end
    advert.update(row)
    true
  end

  def fetch_products(_user)
    {
      "products": [
        {
          "id": 13,
          "title": "Комплект Грет",
          "price": 10000,
          "description": "Lorem ipsum dolor sit amet consectetur.",
          "images": [
            "https://s3.ru1.storage.beget.cloud/5d45320015cb-disorderly-elder/rjp93uaqjf17dhgwdv1xfalrxqsm"
          ]
        }
      ],
      "pagination": {
        "total_count": 1,
        "total_pages": 1,
        "current_page": 1,
        "next_page": null,
        "prev_page": null
      }
    }
  end

  def md5_hash(hash)
    str = hash.values.join
    Digest::MD5.hexdigest(str)
  end
end
