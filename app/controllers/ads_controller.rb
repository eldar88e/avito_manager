class AdsController < ApplicationController
  before_action :authenticate_user!, :set_store
  before_action :set_ad, only: %i[edit update]

  def edit
    render turbo_stream: turbo_stream.update(:main_modal_content, partial: '/ads/form')
  end

  def update
    ad = ad_params
    ad[:deleted] = ad[:deleted] == '1' ? :deleted : :active
    return unless @ad.update(ad)

    render turbo_stream: [
      success_notice('Объявление было успешно обновлено.'),
      turbo_stream.replace(@ad),
      turbo_stream.append('mainModal', '<script>closeModal();</script>'.html_safe)
    ]
  end

  def update_all
    @store.ads.update_all(banned: false, banned_until: nil, updated_at: Time.current)
    set_search_ads
    @pagy, @ads = pagy(@q_ads.result, items: 36)
    render turbo_stream: [
      # turbo_stream.replace(:ads, partial: '/ads/ads_list'),
      # TODO к ссылкам пагинации пристыковывается update_all /stores/10?page=3
      success_notice(t('.success'))
    ]
  end

  private

  def set_ad
    @ad = Ad.find(params[:id])
  end

  def ad_params
    params.require(:ad).permit(:avito_id, :full_address, :file_id, :banned_until, :banned, :deleted)
  end
end
