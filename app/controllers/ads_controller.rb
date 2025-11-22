class AdsController < ApplicationController
  before_action :authenticate_user!, :set_store
  before_action :set_ad, only: %i[edit update]

  def edit
    render turbo_stream: [
      turbo_stream.update(:modal_content, partial: '/ads/form'),
      turbo_stream.update(:modal_title, 'Редактировать объявление')
    ]
  end

  def update
    return unless @ad.update(ad_params)

    render turbo_stream: [turbo_stream.replace(@ad), success_notice('Объявление было успешно обновлено.')]
  end

  def update_all
    @store.ads.update_all(banned: false, banned_until: nil)
    render turbo_stream: success_notice(t('.success'))

    # set_search_ads
    # @pagy, @ads = pagy(@q_ads.result, items: 36)
    # turbo_stream.replace(:ads, partial: '/ads/ads_list'),
    # TODO к ссылкам пагинации пристыковывается update_all /stores/10?page=3
  end

  private

  def set_ad
    @ad = Ad.find(params[:id])
  end

  def ad_params
    params.expect(ad: %i[avito_id full_address file_id banned_until banned deleted])
  end
end
