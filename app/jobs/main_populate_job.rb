class MainPopulateJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user_id = find_user(args)
    ImportProductsJob.perform_now(user_id:)
    WatermarksSheetsJob.perform_later(user_id:)
    Avito::UpdatePriceJob.perform_later(user_id:) if Rails.env.production?
  end
end
