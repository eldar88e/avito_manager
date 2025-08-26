# Run Example TransferFilesToMinioJob.perform_now(user: User.first, klass: 'Ad', column: :image, limit: 2000)

class TransferFilesToMinioJob < ApplicationJob
  queue_as :default

  def perform(**args)
    klass = args[:klass].camelize.constantize
    items = fetch_items(klass, args[:column], args[:limit])
    count = transfer(items, klass, args[:column])
    user  = find_user(args)
    msg   = "✅ Exported to MinIO #{count} for #{klass} attachments"
    TelegramService.call(user, msg)
    Clean::CleanUnattachedBlobsJob.perform_later(user: user) if count.positive?
    nil
  end

  private

  def fetch_items(klass, column, limit = nil)
    klass.includes("#{column}_attachment" => :blob)
         .where(active_storage_blobs: { service_name: 'local' })
         .limit(limit)
  end

  def transfer(items, klass, column)
    count = 0
    items.find_each do |item| # get default 1000 items
      next unless item.send(column).attached?

      local_file = item.send(column).download
      save_attachment(item, local_file, column)
      count += 1
    rescue StandardError => e
      Rails.logger.error "Failed to transfer file for #{klass}: #{item.id}: #{e.message}"
    end
    count
  end

  def save_attachment(item, local_file, column)
    item.send(column).attach(
      io: StringIO.new(local_file),
      filename: item.send(column).filename.to_s,
      content_type: item.send(column).content_type
    )
  end
end
