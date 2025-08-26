class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Backend

  def error_notice(msg, status = :unprocessable_entity)
    render turbo_stream: send_notice(msg, 'danger'), status:
  end

  def success_notice(msg)
    send_notice(msg, 'success')
  end

  private

  def set_store
    return cache_store if params[:store_id]

    @store = current_user.stores.find(params[:id])
    Rails.cache.write("user_#{current_user.id}_store_#{params[:id]}", @store, expires_in: 6.hours)
  end

  def cache_store
    @store = Rails.cache.fetch("user_#{current_user.id}_store_#{params[:store_id]}", expires_in: 6.hours) do
      current_user.stores.find(params[:store_id])
    end
  end

  def set_search_ads
    # @q_ads = @store.ads.includes(image_attachment: :blob).order(created_at: :desc).ransack(params[:q])
  end

  def send_notice(msg, key)
    turbo_stream.append(:notices, partial: '/partials/notices/notice', locals: { notices: msg, key: })
  end
end
