class SaveImageJob < ApplicationJob
  queue_as :default

  def perform(**args)
    adv     = Ad.find(args[:ad_id])
    product = adv.adable
    title   = product.title
    options = make_options(adv)
    process_image(args, options, title, adv)
  rescue StandardError => e
    Rails.logger.error "#{e.class} || #{e.message}\nID: #{product.send(args[:id])}"
    msg = "Аккаунт: #{adv.store.manager_name}\nID: #{product.send(args[:id])}\nТовар: #{title}\nError: #{e.message}"
    TelegramService.call(adv.user, msg)
    raise e
  end

  private

  def make_options(adv)
    product = adv.adable
    {
      store: adv.store,
      address: adv.address,
      settings: fetch_settings(adv.user),
      main_img: product.is_a?(AdImport) ? product.images['first'] : product&.image&.blob
    }
  end

  def fetch_settings(user)
    set_row              = user.settings
    settings             = set_row.all_cached
    blob                 = set_row.find_by(variable: 'main_font')&.font&.blob
    settings[:main_font] = blob if blob
    settings
  end

  def process_image(args, options, name, adv)
    w_service = WatermarkService.new(**options)
    return Rails.logger.error("Not exist main image for #{name}") unless w_service.image_exist?

    image = w_service.add_watermarks
    name  = "#{args[:file_id]}.jpg"
    save_image(adv, name, image)
  end

  def save_image(item, name, image)
    Tempfile.open(%w[image .jpg]) do |temp_img|
      image.write_to_file(temp_img.path)
      temp_img.flush
      item.image.attach(io: File.open(temp_img.path), filename: name, content_type: 'image/jpeg')
    end
  end
end
