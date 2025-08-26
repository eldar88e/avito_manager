class SaveImageJob < ApplicationJob
  queue_as :default

  def perform(**args)
    product = args[:product]
    name    = product.is_a?(Game) ? product.name : product.title
    options = make_options(**args)
    process_image(args, options, name)
  rescue StandardError => e
    Rails.logger.error "#{e.class} || #{e.message}\nID: #{product.send(args[:id])}"
    msg  = "Аккаунт: #{args[:store].manager_name}\nID: #{product.send(args[:id])}\nТовар: #{name}\nError: #{e.message}"
    user = find_user(args)
    TelegramService.call(user, msg)
    raise e
  end

  private

  def make_options(**args)
    {
      store: args[:store],
      address: args[:address],
      settings: args[:settings],
      game: args[:product]
    }
  end

  def process_image(args, options, name)
    w_service = WatermarkService.new(**options)
    return Rails.logger.error("Not exist main image for #{name}") unless w_service.image_exist?

    image = w_service.add_watermarks
    name  = "#{args[:file_id]}.jpg"
    save_image(args[:ad], name, image)
  end

  def save_image(item, name, image)
    Tempfile.open(%w[image .jpg]) do |temp_img|
      image.write(temp_img.path)
      temp_img.flush
      item.image.attach(io: File.open(temp_img.path), filename: name, content_type: 'image/jpeg')
    end
  end
end
