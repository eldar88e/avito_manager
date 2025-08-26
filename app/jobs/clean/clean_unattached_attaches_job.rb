# Job to clean attachments, blobs and file that are not attached

module Clean
  class CleanUnattachedAttachesJob < ApplicationJob
    queue_as :default

    def perform(**args)
      user         = find_user(args)
      record_types = ActiveStorage::Attachment.distinct.pluck(:record_type)
      record_types.each { |record_type| process_records(record_type, user) }
      nil
    end

    private

    def process_records(record_type, user)
      attachments         = ActiveStorage::Attachment.where(record_type:)
      existing_record_ids = record_type.constantize.where(id: attachments.pluck(:record_id)).pluck(:id)
      count               = 0
      attachments.each { |attach| attach.purge && count += 1 unless existing_record_ids.include?(attach.record_id) }
      msg = "⚠️ Cleared #{count} attachments, blobs and files from #{record_type}."
      TelegramService.call(user, msg) if count.positive?
    end
  end
end
