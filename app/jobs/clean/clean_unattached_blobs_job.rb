module Clean
  class CleanUnattachedBlobsJob < ApplicationJob
    queue_as :default

    def perform(**args)
      user             = find_user(args)
      unattached_blobs = ActiveStorage::Blob.unattached
      unattached_blobs.each(&:purge)
      msg = "⚠️ Cleared #{unattached_blobs.size} unattached blobs and images."
      TelegramService.call(user, msg) if unattached_blobs.size.positive?
    end
  end
end
