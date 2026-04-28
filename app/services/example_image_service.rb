class ExampleImageService
  QUALITY = 90

  def initialize(address)
    @store    = address.store
    @address  = address
    @user     = @store.user
  end

  def self.call(address)
    new(address).assemble
  end

  def assemble
    product   = @user.ad_imports.active.order('RANDOM()').limit(1).first
    avito_img = product.images['first']
    main_imgs = [avito_img, product.images['other']&.first].compact_blank.uniq
    return { error: 'Не найдены изображения для тестовой картинки' } if main_imgs.empty?

    save_images(main_imgs, avito_img)
    { success: true }
  rescue StandardError => e
    Rails.logger.error e.message
    { error: e.message }
  end

  private

  def save_images(main_imgs, avito_img)
    @store.test_imgs.purge

    main_imgs.each_with_index do |main_img, index|
      preserve_main_image_size = avito_img == main_img
      w_service = WatermarkService.new(
        store: @store, address: @address, settings: settings, main_img: main_img, preserve_main_image_size:
      )
      next unless w_service.image_exist?

      image = w_service.add_watermarks
      Tempfile.open(%W[test-image-#{index} .jpg]) do |temp_img|
        image.write_to_file("#{temp_img.path}[Q=#{QUALITY}]")
        temp_img.flush
        @store.test_imgs.attach(io: File.open(temp_img.path), filename: "test_#{index + 1}.jpg", content_type: 'image/jpeg')
      end
    end
  end

  def settings
    Setting.all_cached(@store.user_id)
  end
end
