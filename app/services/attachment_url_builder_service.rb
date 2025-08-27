class AttachmentUrlBuilderService
  include Rails.application.routes.url_helpers

  def self.storage_path(attach, variant = nil)
    blob = variant ? attach : attach.blob

    case attach.blob.service_name
    when 'beget' then beget_storage_path(blob)
    when 'local' then local_storage_path(blob)
    else url_for(attach)
    end
  rescue StandardError => e
    Rails.logger.error "Error getting file path: #{e.message}"
    nil
  end

  def self.beget_storage_path(blob)
    bucket   = ENV.fetch('BEGET_BUCKET')
    endpoint = ENV.fetch('BEGET_ENDPOINT')
    key      = blob.key
    "#{endpoint}/#{bucket}/#{key}"
  end

  def self.local_storage_path(blob)
    if Rails.env.production?
      "#{ENV.fetch('HOST')}/storage/#{blob.key[0..1]}/#{blob.key[2..3]}/#{blob.key}"
    else
      url_for(blob)
    end
  end

  def self.url_for(attach)
    Rails.application.routes.url_helpers.rails_blob_url(attach, only_path: true)
  end
end
