require 'vips'

class WatermarkService
  include Rails.application.routes.url_helpers

  DEFAULT_WIDTH      = 1920
  DEFAULT_HEIGHT     = 1440
  DEFAULT_FONT_SIZE  = 42
  DEFAULT_IMG_COLOR  = '#FFFFFF'.freeze
  DEFAULT_COLOR      = [0, 0, 0, 255].freeze
  DEFAULT_TEXT_BACK  = '#00000000'.freeze
  DEFAULT_FONT       = 'sans'.freeze
  TEXT_DPI           = 300

  def initialize(**args)
    @store     = args[:store]
    @settings  = args[:settings]
    # @main_font = make_font @settings[:main_font]
    @reference_width  = (args[:width] || @settings[:avito_img_width] || DEFAULT_WIDTH).to_i
    @reference_height = (args[:height] || @settings[:avito_img_height] || DEFAULT_HEIGHT).to_i
    @main_img = args[:main_img]
    @preserve_main_image_size = args[:preserve_main_image_size]
    @skip_text_layers = args[:skip_text_layers]
    prepare_canvas!
    @new_image = initialize_first_layer
    @add_layer = JSON.parse(args[:add_layer]).transform_keys(&:to_sym) if args[:add_layer].present?
    handle_layers(args[:address])
  end

  def image_exist?
    @main_img.present?
  end

  def add_watermarks
    @layers.each do |layer|
      next if skip_text_layer?(layer)

      layer[:params] = prepare_layer_params(layer[:params])
      layer[:layer_type] == 'text' ? add_text(layer) : add_img(layer)
    end

    @new_image
  end

  private

  def make_font(blob)
    return if blob.blank?

    font_path = Rails.root.join('tmp', 'cache', "#{blob.key}_#{blob.filename}").to_s
    return font_path if File.exist?(font_path)

    File.binwrite(font_path, blob.download)
    font_path
  end

  def initialize_first_layer
    bg_color = @settings[:avito_back_color] || DEFAULT_IMG_COLOR
    rgba     = convert_to_rgba(bg_color)
    img      = Vips::Image.black(@width, @height).new_from_image(rgba)
    img.copy(interpretation: :srgb)
  end

  def handle_layers(address)
    @layers = make_layers_row
    @layers << @add_layer if @add_layer.present?
    @layers << { img: @main_img, menuindex: @store.menuindex,
                 params: @store.img_params.presence || {}, layer_type: 'img' }
    @layers.sort_by! { |layer| layer[:menuindex] }
    @layers << make_slogan(address)
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

  def prepare_layer_params(params)
    result =
      if params.is_a?(Hash)
        params
      elsif params.present?
        eval(params).transform_keys(&:to_s) # TODO: убрать eval
      end
    rewrite_pos_size(result)
  end

  def rewrite_pos_size(args)
    args = args.presence || {}
    formated_args = %w[pos_x pos_y row column].each_with_object({}) do |key, hash|
      scaled_value = scaled_param_value(args[key], key)
      max_value = %w[pos_x row].include?(key) ? @width : @height
      hash[key] = [scaled_value, max_value].min
    end
    args.merge formated_args
  end

  def add_img(layer)
    params     = normalized_img_params(layer)
    raw_image  = load_image(layer[:img])
    image      = resize_image!(raw_image, params, layer)
    @new_image = @new_image.composite2(image, 'over', x: params['pos_x'], y: params['pos_y'])
  end

  def resize_image!(img, params, layer)
    return crop_to_target_aspect(img) if preserve_main_image_size?(layer)

    if params['row'].positive? && params['column'].positive?
      img.thumbnail_image(params['row'], height: params['column'])
    elsif params['column'].positive?
      img.resize params['column'].to_f / img.height
    elsif params['row'].positive?
      img.thumbnail_image(params['row'])
    else
      img
    end
  end

  def add_text(layer)
    return if layer[:title].blank?

    params     = layer[:params]
    rgba       = convert_to_rgba(params['fill'])
    font_size  = scaled_text_value(params['pointsize'].presence || DEFAULT_FONT_SIZE)
    font_back  = convert_to_rgba(params['font_back'].presence || DEFAULT_TEXT_BACK)
    padding    = scaled_text_value(params['font_padding'] || 0)
    radius     = scaled_text_value(params['font_back_radius'] || 0)
    text_mask  = Vips::Image.text(layer[:title], font: "#{DEFAULT_FONT} #{font_size}", dpi: TEXT_DPI)

    text = if padding.positive? || radius.positive?
             build_padded_text(text_mask, rgba, font_back, padding, radius)
           else
             text_mask.ifthenelse(rgba, font_back).copy(interpretation: :srgb)
           end

    @new_image = @new_image.composite2(text, 'over', x: params['pos_x'], y: params['pos_y'])
  end

  def build_padded_text(text_mask, text_color, bg_color, padding, radius)
    bg_w = text_mask.width + padding * 2
    bg_h = text_mask.height + padding * 2

    bg = Vips::Image.black(bg_w, bg_h).new_from_image(bg_color).copy(interpretation: :srgb)

    if radius.positive?
      mask = rounded_rect_mask(bg_w, bg_h, radius)
      bg_rgb   = bg.extract_band(0, n: 3)
      bg_alpha = (bg.extract_band(3).cast(:float) * mask.cast(:float) / 255.0).cast(:uchar)
      bg = bg_rgb.bandjoin(bg_alpha).copy(interpretation: :srgb)
    end

    text_layer = text_mask.ifthenelse(text_color, [0, 0, 0, 0]).copy(interpretation: :srgb)
    bg.composite2(text_layer, 'over', x: padding, y: padding)
  end

  def rounded_rect_mask(width, height, radius)
    r = [radius, width / 2, height / 2].min.to_f
    xy = Vips::Image.xyz(width, height)
    x = xy[0]
    y = xy[1]

    tl = (x < r) & (y < r) & (((x - r)**2 + (y - r)**2) > r**2)
    tr = (x >= width - r) & (y < r) & (((x - width + r)**2 + (y - r)**2) > r**2)
    bl = (x < r) & (y >= height - r) & (((x - r)**2 + (y - height + r)**2) > r**2)
    br = (x >= width - r) & (y >= height - r) & (((x - width + r)**2 + (y - height + r)**2) > r**2)

    outside = tl | tr | bl | br
    outside.ifthenelse(0, 255).cast(:uchar)
  end

  def convert_to_rgba(color)
    str = color.to_s.strip.downcase
    return DEFAULT_COLOR unless str.start_with?('#')

    hex = str[1..]
    case hex.size
    when 8
      hex.scan(/../).map(&:hex)
    when 6
      hex.scan(/../).map(&:hex) << 255
    else
      DEFAULT_COLOR
    end
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

  def form_img_layer(row_layer)
    layer = build_layer(row_layer)
    layer.merge(img: row_layer.layer.blob)
  end

  def build_layer(layer)
    {
      params: layer.layer_params.presence || {},
      menuindex: layer.menuindex,
      layer_type: layer.layer_type,
      title: layer.title
    }
  end

  def prepare_canvas!
    if @preserve_main_image_size && @main_img.present?
      @prepared_main_img = crop_to_target_aspect(load_image(@main_img))
      @width = @prepared_main_img.width
      @height = @prepared_main_img.height
    else
      @width = @reference_width
      @height = @reference_height
    end
  end

  def scaled_param_value(value, key)
    raw_value = value.to_i
    return raw_value unless @preserve_main_image_size

    scale = %w[pos_x row].include?(key) ? width_scale : height_scale
    (raw_value * scale).round
  end

  def width_scale
    @width.to_f / @reference_width
  end

  def height_scale
    @height.to_f / @reference_height
  end

  def preserve_main_image_size?(layer)
    @preserve_main_image_size && layer[:img] == @main_img
  end

  def skip_text_layer?(layer)
    @skip_text_layers && layer[:layer_type].to_s == 'text'
  end

  def crop_to_target_aspect(img)
    source_ratio = img.width.to_f / img.height
    target_ratio = @reference_width.to_f / @reference_height

    if source_ratio > target_ratio
      crop_width = (img.height * target_ratio).round
      left = [(img.width - crop_width) / 2, 0].max
      img.crop(left, 0, crop_width, img.height)
    elsif source_ratio < target_ratio
      crop_height = (img.width / target_ratio).round
      top = [(img.height - crop_height) / 2, 0].max
      img.crop(0, top, img.width, crop_height)
    else
      img
    end
  end

  def load_image(url_or_blob)
    return @prepared_main_img if @prepared_main_img && url_or_blob == @main_img

    data = url_or_blob.is_a?(ActiveStorage::Blob) ? url_or_blob.download : URI.open(url_or_blob).read
    Vips::Image.new_from_buffer(data, '')
  end

  def normalized_img_params(layer)
    return layer[:params] unless preserve_main_image_size?(layer)

    layer[:params].merge('pos_x' => 0, 'pos_y' => 0, 'row' => @width, 'column' => @height)
  end

  def scaled_text_value(value)
    raw_value = value.to_i
    return raw_value unless @preserve_main_image_size

    (raw_value * [width_scale, height_scale].min).round
  end
end
