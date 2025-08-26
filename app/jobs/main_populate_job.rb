class MainPopulateJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user = find_user(args)
    ImportProductsJob.perform_now(user:)
    WatermarksSheetsJob.perform_later(user:)
    Avito::UpdatePriceJob.perform_later(user:) if Rails.env.production?
  end
end
