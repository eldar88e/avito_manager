class WatermarksSheetsJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user     = find_user(args)
    stores   = [
      args[:store] || user.stores.includes(:addresses).active.where(addresses: { active: true })
    ].flatten.compact
    stores.each { |store| process_store(user.id, store.id, args[:clean]) }
    nil
  end

  private

  def process_store(user_id, store_id, clean)
    # %w[ad_import, product].each { |model| AddWatermarkJob.perform_now(user:, model:, store:, settings:, clean:) }
    AddWatermarkJob.perform_now(user_id:, model: 'ad_import', store_id:, clean:)
    PopulateExcelJob.perform_now(store_id:)
  end
end
