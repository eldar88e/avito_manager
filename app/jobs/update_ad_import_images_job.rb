class UpdateAdImportImagesJob < AddWatermarkJob
  queue_as :default

  def perform(**args)
    user      = find_user(args)
    store     = user.stores.active.find(args[:store_id])
    ad_import = user.ad_imports.active.find(args[:ad_import_id])
    addresses = store.addresses.active
    count     = [0]

    addresses.each { |address| process_product(ad_import, address, args[:clean], count) }

    msg = if addresses.empty?
            'No active address!'
          else
            cities = addresses.map(&:city).join("\n")
            "🏞 Updated #{count[0]} image(s) for AdImport ##{ad_import.id} for #{store.manager_name} for:\n#{cities}"
          end
    broadcast_notify(msg)
    TelegramService.call(user, msg) if addresses.any? && args[:notify]
    Clean::CleanUnattachedBlobsJob.perform_later(user: user) if args[:clean]
  rescue StandardError => e
    Rails.logger.error("#{self.class} - #{e.message}")
    TelegramService.call(user, "Error #{self.class} || #{e.message}")
  end
end
