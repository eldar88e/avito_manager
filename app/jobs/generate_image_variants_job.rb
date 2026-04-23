class GenerateImageVariantsJob < ApplicationJob
  queue_as :default

  def perform(blob_ids)
    return if [blob_ids].flatten.blank?

    blobs = ActiveStorage::Blob.where(id: blob_ids)
    GenerateImageService.call(blobs)
  end
end
