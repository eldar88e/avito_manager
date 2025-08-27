class WatermarkService
  include Rails.application.routes.url_helpers
  include Magick

  BLOB_CACHE_EXPIRES = 30.minutes
  DEFAULT_WIDTH      = 1920
  DEFAULT_HEIGHT     = 1440
  DEFAULT_FONT_SIZE  = 42
  DEFAULT_COLOR      = 'white'.freeze
  DEFAULT_FONT       = 'Arial'.freeze

  def initialize(**args)
    @game      = args[:game]
    @store     = args[:store]
    @settings  = args[:settings]
    @main_font = make_font @settings[:main_font]
    @width     = (@settings[:avito_img_width] || DEFAULT_WIDTH).to_i
    @height    = (@settings[:avito_img_height] || DEFAULT_HEIGHT).to_i
    @new_image = initialize_first_layer
    @main_img  = @game.is_a?(AdImport) ? @game.images['first'] : @game&.image&.blob
    handle_layers(args[:address])
  end

  def image_exist?
    @main_img.present?
  end

  def add_watermarks
    @layers.each do |layer|
      layer[:params] = prepare_layer_params(layer[:params])
      layer[:layer_type] == 'text' ? add_text(layer) : add_img(layer)
    end

    @new_image
  end

  private

  def handle_layers(address)
    @layers = make_layers_row
    @layers << { img: @main_img, menuindex: @store.menuindex,
                 params: @store.img_params.presence || {}, layer_type: 'img' }
    @layers.sort_by! { |layer| layer[:menuindex] }
    @layers << make_slogan(address)
  end

  def prepare_layer_params(params)
    result =
      if params.is_a?(Hash)
        params
      elsif params.present?
        # eval(params).transform_keys(&:to_s) # TODO: убрать eval
        JSON.parse(params.gsub('=>', ':'))
      end
    rewrite_pos_size(result)
  rescue JSON::ParserError
    Rails.logger.error "Failed to parse layer params: #{params}!"
    {}
  end

  def rewrite_pos_size(args)
    return {} if args.blank?

    formated_args           = {}
    formated_args['pos_x']  = min_value(args['pos_x'], @width)
    formated_args['pos_y']  = min_value(args['pos_y'], @height)
    formated_args['row']    = min_value(args['row'], @width)
    formated_args['column'] = min_value(args['column'], @height)

    args.merge formated_args
  end

  def min_value(value, max_value)
    value.present? ? [value.to_i, max_value].min : nil
  end

  def add_img(layer)
    url        = layer[:img] # cached_blob(layer[:img])
    image_data = URI.open(url).read
    img  = Magick::Image.from_blob(image_data).first # Image.read(layer[:img]).first
    resize_image!(img, layer[:params])
    @new_image.composite!(img, layer[:params]['pos_x'] || 0, layer[:params]['pos_y'] || 0, OverCompositeOp)
  end

  def resize_image!(img, params)
    return if !params['column'].to_i.positive? && !params['row'].to_i.positive?

    img.resize_to_fit!(params['row'], params['column'])
  end

  def add_text(layer)
    return if layer[:title].blank?

    text_obj = prepare_text_object(layer)
    annotate_image(text_obj, layer[:params], layer[:title])
  end

  def prepare_text_object(layer)
    params             = layer[:params]
    text_obj           = Draw.new
    text_obj.font      = make_font(layer[:img]) || @main_font || DEFAULT_FONT
    text_obj.pointsize = params['pointsize'] || DEFAULT_FONT_SIZE
    text_obj.fill      = params['fill'] || DEFAULT_COLOR
    text_obj.stroke    = params['stroke'] || DEFAULT_COLOR
    text_obj.gravity   = make_gravity(params['gravity'])
    text_obj
  end

  def annotate_image(text_obj, params, title)
    row    = params['row'] || 0
    column = params['column'] || 0
    pos_x  = params['pos_x'] || 0
    pos_y  = params['pos_y'] || 0

    text_obj.annotate(@new_image, row, column, pos_x, pos_y, title)
  end

  def make_font(blob)
    return if blob.blank?

    font_path = Rails.root.join('tmp', 'cache', "#{blob.key}_#{blob.filename}").to_s
    return font_path if File.exist?(font_path)

    File.binwrite(font_path, blob.download)
    font_path
  end

  def make_gravity(gravity)
    { 'top_left' => NorthWestGravity,
      'top_center' => NorthGravity,
      'top_right' => NorthEastGravity,
      'middle_left' => WestGravity,
      'middle_center' => CenterGravity,
      'middle_right' => EastGravity,
      'bottom_left' => SouthWestGravity,
      'bottom_center' => SouthGravity,
      'bottom_right' => SouthEastGravity }[gravity] || NorthWestGravity
  end

  def make_layers_row
    @store.image_layers.active.filter_map do |layer|
      if layer.layer.attached?
        form_img_layer(layer)
      elsif layer.layer_type == 'text' && layer.title.present?
        build_layer(layer)
      end
    end
  end

  def build_layer(layer)
    { params: layer.layer_params.presence || {},
      menuindex: layer.menuindex,
      layer_type: layer.layer_type,
      title: layer.title }
  end

  def form_img_layer(row_layer)
    layer = build_layer(row_layer)
    layer.merge(img: row_layer.layer.blob)
  end

  def make_slogan(address)
    slogan = { title: address.slogan, params: address.slogan_params || {} }
    if address.image.attached?
      blob                = address.image.blob
      slogan[:img]        = blob
      slogan[:layer_type] = 'img' if blob[:content_type].include?('image')
    end
    slogan[:layer_type] = 'text' unless slogan[:layer_type]
    slogan
  end

  def initialize_first_layer
    Image.new(@width, @height) do |c|
      c.background_color = @settings[:avito_back_color] || DEFAULT_COLOR
      # c.format           = 'JPEG'
      # c.interlace        = PlaneInterlace
    end
  end

  def cached_blob(blob)
    # TODO: можно хранить в tmp если будет потреблять много ОЗУ
    Rails.cache.fetch("cache_watermark_#{blob.key}", expires_in: BLOB_CACHE_EXPIRES) { blob.download }
  end
end
