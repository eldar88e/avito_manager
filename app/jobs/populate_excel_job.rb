class PopulateExcelJob < ApplicationJob
  queue_as :default

  include Rails.application.routes.url_helpers

  COLUMNS_NAME = %w[
    Id AvitoId DateBegin AdStatus Category GoodsType AdType Availability Address Title Description Condition Price
    AllowEmail ManagerName ContactPhone ContactMethod ImageUrls GoodsSubType Color ColorName FurnitureShape Modular
    FoldingMechanism TypeOfFoldingMechanism SleepingPlace UpholsteryMaterial Width Depth Height Length
  ].freeze
  EXTRA_COLUMNS_SIZE = 12

  def perform(**args)
    store     = Store.find(args[:store_id])
    user      = store.user
    settings  = user.settings.all_cached
    workbook  = FastExcel.open
    worksheet = workbook.add_worksheet('list')
    worksheet.append_row(COLUMNS_NAME)
    # products = user.products.active.with_attached_image
    store.addresses.where(active: true).find_each do |address|
      ad_imports_ads = address.ads.active_ads.for_ad_import
      ad_imports     = active_ad_import(address, settings)
      ad_imports.each { |ad_import| process_game(ad_import, address, ad_imports_ads, worksheet) }
      # product_ads = address.ads.active_ads.for_product
      # products.each { |product| process_product(product, address, product_ads, worksheet) }
    end

    content   = workbook.read_string
    xlsx_path = "./public/adverts_list/#{store.var}.xlsx"
    File.binwrite(xlsx_path, content)
    url = Rails.env.production? ? "https://#{ENV.fetch('HOST')}" : 'http://localhost:3000'
    msg = "✅ File #{url}#{xlsx_path.sub('./public', '')} is updated!"
    broadcast_notify(msg)
    TelegramService.call(user, msg)
  rescue StandardError => e
    Rails.logger.error("Error #{self.class} || #{e.message}")
    TelegramService.call(user, "Error #{self.class} || #{e.message}")
  end

  private

  def active_ad_import(address, settings)
    AdImport.active.limit(address.total_games || settings['quantity_games']) # .includes(:game_black_list)
  end

  def process_game(game, address, ads, worksheet)
    # return if game.game_black_list

    store        = address.store
    current_time = Time.current.strftime('%d.%m.%y')
    ad           = ads.find { |i| i[:file_id] == "#{game.external_id}_#{store.id}_#{address.id}" }
    img_url      = make_image(ad&.image)
    return if img_url.blank?

    worksheet.append_row(
      [ad.id, ad.avito_id, current_time, store.ad_status, store.category, store.goods_type,
       store.ad_type, store.availability, ad.full_address || address.store_address, game.title,
       make_description(game, store, address), store.condition, game.price, store.allow_email, store.manager_name,
       store.contact_phone, store.contact_method, img_url, game.category, *form_extra(game)]
    )
  end

  # def process_product(product, address, ads, worksheet)
  #   store   = address.store
  #   ad      = ads.find { |i| i[:file_id] == "#{product.id}_#{store.id}_#{address.id}" }
  #   img_url = make_image(ad&.image)
  #   return if img_url.blank?
  #
  #   current_time = Time.current.strftime('%d.%m.%y')
  #   worksheet.append_row(
  #     [ad.id, ad.avito_id, current_time, product.ad_status || store.ad_status, product.category || store.category,
  #      product.goods_type || store.goods_type, product.ad_type || store.ad_type, product.type || store.type,
  #      product.platform, product.localization, ad.full_address || address.store_address, product.title,
  #      make_description(product, store, address), product.condition || store.condition, product.price,
  #      product.allow_email || store.allow_email, store.manager_name, store.contact_phone,
  #      product.contact_method || store.contact_method, img_url]
  #   )
  # end

  def form_extra(game)
    COLUMNS_NAME.last(EXTRA_COLUMNS_SIZE).map do |column|
      column_underscored = column.underscore
      if %w[sleeping_place folding_mechanism].include?(column_underscored)
        game.extra&.dig(column_underscored) ? 'Eсть' : 'Нет'
      elsif column_underscored == 'modular'
        game.extra&.dig(column_underscored) ? 'Да' : 'Нет'
      else
        game.extra&.dig(column_underscored)
      end
    end
  end

  def make_image(image)
    AttachmentUrlBuilderService.storage_path(image)
  end

  def make_description(model, store, address)
    DescriptionService.call(model:, store:, address_desc: address.description)
  end
end
