class MainPopulateJob < ApplicationJob
  queue_as :default

  def perform(**args)
    user = find_user(args)
    ImportProductsJob.perform_now(user.id)
    WatermarksSheetsJob.perform_later(user.id)
    Avito::UpdatePriceJob.perform_later(user.id) if Rails.env.production?
  end
end
