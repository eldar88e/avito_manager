class GenerateImageService
  PARAMS = { metadata_directive: 'REPLACE', cache_control: 'public, max-age=31536000, immutable' }.freeze
  VARIANT_NAMES = {
    ad: { images: %i[thumb] }
  }.freeze

  def self.call(blobs)
    new(blobs).generate
  end

  def initialize(blobs)
    @blobs = blobs
    @s3_client, @bucket = ensure_s3_service
  end

  def generate
    return if @s3_client.nil? || @blobs.blank?

    @blobs.includes(:attachments).find_each do |blob|
      process_blob_variants(blob) if blob.attachments.any?
      copy_object(blob.key, blob.content_type)
    end
  end

  private

  def process_blob_variants(blob)
    blob.attachments.each do |attachment|
      variant_names = fetch_variants(attachment)
      variant_names.each do |variant_name|
        variant = attachment.variant(variant_name).processed
        copy_object(variant.key, variant.content_type)
      end
    end
  end

  def fetch_variants(attachment)
    result = VARIANT_NAMES.dig(attachment.record_type.downcase.to_sym, attachment.name.to_sym) || []
    Rails.logger.error "No variants found for #{attachment.record_type}# — #{attachment.name}" if result.blank?

    result
  end

  def copy_object(key, content_type)
    @s3_client.copy_object(
      bucket: @bucket,
      key: key,
      copy_source: "#{@bucket}/#{key}",
      content_type: content_type,
      **PARAMS
    )
  rescue StandardError => e
    Rails.logger.error "Failed to update cache control for #{key}: #{e.message}"
  end

  def ensure_s3_service
    service = ActiveStorage::Blob.service

    if service.is_a?(ActiveStorage::Service::S3Service)
      [service.client.client, service.bucket.name]
    else
      Rails.logger.info "Skipping cache control update for #{service.class}"
      nil
    end
  end
end
