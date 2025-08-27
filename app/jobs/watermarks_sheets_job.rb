class WatermarksSheetsJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user     = find_user(args)
    stores   = [
      args[:store] || user.stores.includes(:addresses).active.where(addresses: { active: true })
    ].flatten.compact
    settings = fetch_settings(user)
    stores.each { |store| process_store(user, store, settings, args[:clean]) }
    nil
  end

  private

  def fetch_settings(user)
    set_row              = user.settings
    settings             = set_row.all_cached
    blob                 = set_row.find_by(variable: 'main_font')&.font&.blob
    settings[:main_font] = blob if blob
    settings
  end

  def process_store(user, store, settings, clean)
    # [AdImport, Product]
    [AdImport].each { |model| AddWatermarkJob.perform_now(user:, model:, store:, settings:, clean:) }
    PopulateExcelJob.perform_now(store:)
  end
end
