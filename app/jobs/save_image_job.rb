class SaveImageJob < ApplicationJob
  queue_as :default

  def perform(**args)
    ad      = Ad.find(args[:ad_id])
    user    = ad.user
    product = ad.adable
    store   = ad.store
    name    = product.is_a?(AdImport) ? product.name : product.title
    options = make_options(user, ad)
    process_image(args, options, name, ad)
  rescue StandardError => e
    Rails.logger.error "#{e.class} || #{e.message}\nID: #{product.send(args[:id])}"
    msg  = "Аккаунт: #{store.manager_name}\nID: #{product.send(args[:id])}\nТовар: #{name}\nError: #{e.message}"
    TelegramService.call(user, msg)
    raise e
  end

  private

  def make_options(user, ad)
    {
      store: ad.store,
      address: ad.address,
      settings: fetch_settings(user),
      game: ad.adable
    }
  end

  def fetch_settings(user)
    set_row              = user.settings
    settings             = set_row.all_cached
    blob                 = set_row.find_by(variable: 'main_font')&.font&.blob
    settings[:main_font] = blob if blob
    settings
  end

  def process_image(args, options, name, ad)
    w_service = WatermarkService.new(**options)
    return Rails.logger.error("Not exist main image for #{name}") unless w_service.image_exist?

    image = w_service.add_watermarks
    name  = "#{args[:file_id]}.jpg"
    save_image(ad, name, image)
  end

  def save_image(item, name, image)
    Tempfile.open(%w[image .jpg]) do |temp_img|
      image.write(temp_img.path)
      temp_img.flush
      item.image.attach(io: File.open(temp_img.path), filename: name, content_type: 'image/jpeg')
    end
  end
end
