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
    @width     = (@settings[:avito_img_width] || DEFAULT_WIDTH).to_i
    @height    = (@settings[:avito_img_height] || DEFAULT_HEIGHT).to_i
    @new_image = initialize_first_layer
    @main_img  = args[:main_img]
    @add_layer = JSON.parse(args[:add_layer]).transform_keys(&:to_sym) if args[:add_layer].present?
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
      max_value = %w[pos_x row].include?(key) ? @width : @height
      hash[key] = [args[key].to_i, max_value].min
    end
    args.merge formated_args
  end

  def add_img(layer)
    raw_image  = load_image(layer[:img])
    image      = resize_image!(raw_image, layer[:params])
    @new_image = @new_image.composite2(image, 'over', x: layer[:params]['pos_x'], y: layer[:params]['pos_y'])
  end

  def load_image(url_or_blob)
    data = url_or_blob.is_a?(ActiveStorage::Blob) ? url_or_blob.download : URI.open(url_or_blob).read
    Vips::Image.new_from_buffer(data, '')
  end

  def resize_image!(img, params)
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
    font_size  = params['pointsize'].presence || DEFAULT_FONT_SIZE
    font_back  = convert_to_rgba params['font_back'].presence || DEFAULT_TEXT_BACK
    text_mask  = Vips::Image.text(layer[:title], font: "#{DEFAULT_FONT} #{font_size}", dpi: TEXT_DPI)
    text       = text_mask.ifthenelse(rgba, font_back).copy(interpretation: 'srgb')
    @new_image = @new_image.composite2(text, 'over', x: params['pos_x'], y: params['pos_y'])
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
end
