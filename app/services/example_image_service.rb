class ExampleImageService
  def initialize(address)
    @store    = address.store
    @address  = address
    @settings = settings
  end

  def self.call(address)
    new(address).assemble
  end

  def assemble
    game      = Game.active.order(:top).first
    w_service = WatermarkService.new(store: @store, address: @address, settings: @settings, game:)
    return unless w_service.image_exist?

    save_image(w_service)
  end

  private

  def save_image(w_service)
    image = w_service.add_watermarks
    Tempfile.open(%w[image .jpg]) do |temp_img|
      image.write(temp_img.path)
      temp_img.flush
      @store.test_img.attach(io: File.open(temp_img.path), filename: 'test.jpg', content_type: 'image/jpeg')
    end
  end

  def settings
    set_row              = @store.user.settings
    settings             = set_row.pluck(:var, :value).to_h.transform_keys(&:to_sym)
    blob                 = set_row.find_by(var: 'main_font')&.font&.blob
    # settings[:main_font] = blob.service.path_for(blob.key) if blob
    settings[:main_font] = blob if blob
    settings
  end
end
