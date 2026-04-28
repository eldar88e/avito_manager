class SaveImageJob < ApplicationJob
  queue_as :default

  QUALITY = 90

  def perform(**args)
    adv     = Ad.find(args[:ad_id])
    options = make_options(adv, args[:image_url], args[:add_layer], args[:preserve_main_image_size])
    process_image(options, adv)
  rescue StandardError => e
    Rails.logger.error "#{e.class} || #{e.message}\nID: #{adv.adable.id}"
  end

  private

  def make_options(adv, image, add_layer, preserve_main_image_size)
    {
      store: adv.store,
      address: adv.address,
      settings: fetch_settings(adv.user),
      main_img: image,
      add_layer: add_layer,
      preserve_main_image_size: preserve_main_image_size
    }
  end

  def fetch_settings(user)
    Rails.cache.fetch("settings_#{user.id}", expires_in: 10.minutes) do
      settings             = Setting.all_cached(user.id)
      blob                 = user.settings.find_by(variable: 'main_font')&.font&.blob
      settings[:main_font] = blob if blob # TODO: разобраться со шрифтом для vips
      settings
    end
  end

  def process_image(options, adv)
    w_service = WatermarkService.new(**options)
    return Rails.logger.error("Not exist main image for #{adv.adable.title}") unless w_service.image_exist?

    image = w_service.add_watermarks
    name  = "#{adv.file_id}.jpg"
    save_image(adv, name, image)
  end

  def save_image(item, name, image)
    Tempfile.open(%w[image .jpg], binmode: true) do |temp_img|
      image.write_to_file("#{temp_img.path}[Q=#{QUALITY}]")
      temp_img.flush

      File.open(temp_img.path, 'rb') do |file|
        item.images.attach(io: file, filename: name, content_type: 'image/jpeg')
        enqueue_image_variants(item)
      end
    end
  end

  def enqueue_image_variants(item)
    blob_id = item.images.attachments.last&.blob_id
    GenerateImageVariantsJob.perform_later(blob_id) if blob_id.present?
  end
end
