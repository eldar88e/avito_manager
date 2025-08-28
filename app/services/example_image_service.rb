class ExampleImageService
  def initialize(user, address)
    @store    = address.store
    @address  = address
    @user     = user
  end

  def self.call(user, address)
    new(user, address).assemble
  end

  def assemble
    product   = @user.ad_imports.active.order(:created_at).first
    main_img  = product.images['first']
    w_service = WatermarkService.new(store: @store, address: @address, settings: settings, main_img: main_img)
    return unless w_service.image_exist?

    save_image(w_service)
    { success: true }
  rescue StandardError => e
    Rails.logger.error e.message
    { error: e.message }
  end

  private

  def save_image(w_service)
    image = w_service.add_watermarks
    Tempfile.open(%w[image .jpg]) do |temp_img|
      image.write_to_file(temp_img.path)
      temp_img.flush
      @store.test_img.attach(io: File.open(temp_img.path), filename: 'test.jpg', content_type: 'image/jpeg')
    end
  end

  def settings
    @store.user.settings.all_cached
  end
end
