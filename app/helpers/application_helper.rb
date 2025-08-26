module ApplicationHelper
  include Pagy::Frontend

  def img_resize(image, **args)
    return unless image.attached?

    height  = args[:height] || args[:width]
    variant = image.variant(resize_to_limit: [args[:width], height]).processed
    storage_path(variant, true)
  end

  def format_date(date)
    return date.strftime('%H:%M %d.%m.%Yг.') if date.instance_of?(ActiveSupport::TimeWithZone)

    Time.zone.parse(date).strftime('%H:%M %d.%m.%Yг.') if date.present?
  end

  def active_item(model)
    model.active ? '' : ' list-group-item-danger'
  end

  def paginator(ends, starts = 0)
    return [*starts..ends] if ends < 5

    max  = starts.zero? ? 4 : 5
    page = make_page(starts, ends)
    if page < max
      [starts, starts + 1, starts + 2, starts + 3, starts + 4, '...', ends]
    elsif page.between?(ends - 3, ends)
      [starts, '...', ends - 4, ends - 3, ends - 2, ends - 1, ends]
    else
      [starts, '...', page - 1, page, page + 1, '...', ends]
    end
  end

  def truncate_string(str, max_length)
    return if str.nil?

    str.length > max_length ? "#{str[0, max_length]}..." : str
  end

  private

  def make_page(starts, ends)
    page = params[:page].present? && params[:page].to_i.positive? ? params[:page].to_i : starts
    [page, ends].min
  end

  def storage_path(attach, variant = nil)
    blob = variant ? attach : attach.blob
    if attach.blob.service_name == 'minio'
      "https://#{ENV.fetch('MINIO_HOST')}:9000/#{ENV.fetch('MINIO_BUCKET')}/#{blob.key}"
    else
      url_for attach
    end
  rescue StandardError => e
    Rails.logger.error "Error getting file path: #{e.message}"
    nil
  end

  def noimage_url
    vite_asset_path('images/noimage.png')
  end
end
