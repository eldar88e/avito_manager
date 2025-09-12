class JobsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_settings, only: %i[update_img update_store_test_img]

  def update_store_test_img
    @store  = current_user.stores.active.find(store_id)
    address = @store.addresses.find(params[:address_id])
    result  = ExampleImageService.call(current_user, address)
    return error_notice('Не удалось создать тестовую картинку.') if result[:error]

    render turbo_stream: [
      turbo_stream.update(:test_img, partial: '/stores/test_img'),
      success_notice('Тестовая картинка успешна обновлена!')
    ]
  end

  def update_img
    store  = params[:product] ? nil : current_user.stores.active.find(store_id)
    clean  = params[:clean].present?
    models = []
    models << AdImport if params[:ad_import]
    # models << Product if params[:product] || current_user.products.active.exists?
    # TODO: uncomment when Product will be added

    models.each do |model|
      AddWatermarkJob.perform_later(
        user: current_user,
        notify: !params[:product],
        model:,
        store:,
        clean:,
        address_id: params[:address_id],
        all: params[:product].present?,
        settings: @settings
      )
    end
    job_type = clean ? 'пересозданию' : 'созданию'
    msg      = t('controllers.jobs.update_img.success', job_type:, models: models.join(', '))
    render turbo_stream: success_notice(msg)
  end

  def update_feed
    store = current_user.stores.active.find(store_id)
    WatermarksSheetsJob.perform_later(store:, user: current_user)
    render turbo_stream: success_notice(t('controllers.jobs.update_feed.success', name: store.manager_name))
  end

  def update_ban_list
    store = current_user.stores.active.find(store_id)
    Avito::CheckErrorsJob.perform_later(store:)
    render turbo_stream: success_notice(t('controllers.jobs.update_ban_list.success', name: store.manager_name))
  end

  private

  def store_id
    params.require(:store_id).to_i
  end

  def set_settings
    settings              = current_user.settings
    @settings             = settings.all_cached
    blob                  = settings.find_by(variable: 'main_font')&.font&.blob
    # @settings[:main_font] = blob.service.path_for(blob.key) if blob
    @settings[:main_font] = blob if blob
  end
end
