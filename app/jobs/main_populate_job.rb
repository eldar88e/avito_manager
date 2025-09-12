class MainPopulateJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user_id = find_user(args)
    edited  = ImportProductsJob.perform_now(user_id:)
    WatermarksSheetsJob.perform_later(user_id:) if edited.positive?
    Avito::UpdatePriceJob.perform_later(user_id:) if Rails.env.production?
  end
end
