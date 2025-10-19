class SaveImageJob < ApplicationJob
  queue_as :default

  IMG_LIMIT = 0..8

  def perform(**args)
    adv     = Ad.find(args[:ad_id])
    product = adv.adable
    image   = product.is_a?(AdImport) ? product.images['first'] : product&.image&.blob
    options = make_options(adv, image)
    process_image(args, options, adv)
    if product.is_a?(AdImport) && product.images['other'].present?
      product.images['other'][IMG_LIMIT].each do |image|
        options = make_options(adv, image)
        process_image(args, options, adv)
      end
    end
  rescue StandardError => e
    Rails.logger.error "#{e.class} || #{e.message}\nID: #{product.send(args[:id])}"
    msg = "Аккаунт: #{adv.store.manager_name}\nID: #{product.send(args[:id])}"
    msg += "\nТовар: #{adv.adable.title}\nError: #{e.message}"
    TelegramService.call(adv.user, msg)
    raise e
  end

  private

  def make_options(adv, image)
    {
      store: adv.store,
      address: adv.address,
      settings: fetch_settings(adv.user),
      main_img: image
    }
  end

  def fetch_settings(user)
    set_row              = user.settings
    settings             = set_row.all_cached
    blob                 = set_row.find_by(variable: 'main_font')&.font&.blob
    settings[:main_font] = blob if blob
    settings
  end

  def process_image(args, options, adv)
    w_service = WatermarkService.new(**options)
    return Rails.logger.error("Not exist main image for #{adv.adable.title}") unless w_service.image_exist?

    image = w_service.add_watermarks
    name  = "#{args[:file_id]}.jpg"
    save_image(adv, name, image)
  end

  def save_image(item, name, image)
    Tempfile.open(%w[image .jpg], binmode: true) do |temp_img|
      image.write_to_file(temp_img.path)
      temp_img.flush

      File.open(temp_img.path, 'rb') do |file|
        item.images.attach(io: file, filename: name, content_type: 'image/jpeg')
      end
    end
  end
end
