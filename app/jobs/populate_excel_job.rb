class PopulateExcelJob < ApplicationJob
  queue_as :default

  include Rails.application.routes.url_helpers

  MAIN_COLUMNS = %w[
    Id AvitoId DateBegin AdStatus Category GoodsType AdType Availability Address Title Description Condition Price
    AllowEmail ManagerName ContactPhone ContactMethod ImageUrls GoodsSubType
  ].freeze
  ADDITIONAL_COLUMNS = %w[
    Color ColorName FurnitureShape Modular FoldingMechanism TypeOfFoldingMechanism SleepingPlace UpholsteryMaterial
    Width Depth Height Length ConditionSleepingPlace FurnitureType MechanismCondition SofaCorner FurnitureFrame
    CabinetType Purpose Material SleepingPlaceWidth SleepingPlaceLength
  ].freeze
  COLUMNS_NAME = MAIN_COLUMNS + ADDITIONAL_COLUMNS
  EXTRA_COLUMNS_SIZE = ADDITIONAL_COLUMNS.size
  PREFIX = { 'Кровати' => 'Кровать', 'Диваны' => 'Диван', 'Тумбы' => 'Тумба', 'Мини-Диваны' => 'Мини-Диван' }.freeze

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
      ad_imports.each { |ad_import| process_ad_import(ad_import, address, ad_imports_ads, worksheet) }
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
    AdImport.active.order(created_at: :desc).limit(address.total_games || settings['quantity_games']) # .includes(:game_black_list)
  end

  def process_ad_import(game, address, ads, worksheet)
    # return if ad_import.game_black_list

    store        = address.store
    current_time = Time.current.strftime('%d.%m.%y')
    prefix       = "#{game.external_id}_#{store.id}_#{address.id}"
    selected_ads = ads.select { |i| i[:file_id].start_with?(prefix) }

    selected_ads.each do |ad|
      img_urls = ad.images.map { |img| make_image(img) }.join('|')
      next if img_urls.blank?

      goods_type = game.category == 'Тумбы' ? 'Подставки и тумбы' : store.goods_type
      category   = game.category.sub('Мини-', '')
      title      = formit_title(game, ad)
      worksheet.append_row(
        [ad.id, ad.avito_id, current_time, store.ad_status, store.category, goods_type, store.ad_type, store.availability,
         ad.full_address, title, make_description(ad, title), store.condition, game.price,
         store.allow_email, store.manager_name, store.contact_phone, store.contact_method, img_urls,
         category, *form_extra(game, ad)]
      )
    end
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

  def form_extra(product, adv)
    COLUMNS_NAME.last(EXTRA_COLUMNS_SIZE).map do |column|
      column_underscored = column.underscore
      if %w[sleeping_place folding_mechanism].include?(column_underscored)
        product.extra&.dig(column_underscored) ? 'Есть' : 'Нет'
      elsif column_underscored == 'modular'
        product.extra&.dig(column_underscored) ? 'Да' : 'Нет'
      else
        adv.extra&.dig(column_underscored).presence || product.extra&.dig(column_underscored)
      end
    end
  end

  def make_image(image)
    AttachmentUrlBuilderService.storage_path(image)
  end

  def make_description(adv, title)
    replacements = {
      title: title || adv.adable.title,
      description: adv.store.description,
      manager: adv.store.manager_name,
      addr_desc: adv.address.description.to_s,
      desc_product: adv.adable.description,
      size: adv.extra.present? ? adv.extra['width'] : nil # && adv.adable.category == 'Кровати'
    }
    description = adv.adable_type == 'AdImport' ? adv.store.desc_ad_import : adv.store.desc_product
    DescriptionService.call(description, replacements)
  end

  def formit_title(product, adv)
    prefix = PREFIX[product.category]
    prefix = "#{adv.extra['furniture_type']} #{prefix}" if product.category == 'Кровати' && adv.extra.present?
    prefix = "#{adv.extra['furniture_shape']} #{prefix}" if product.category == 'Диваны' && adv.extra['furniture_shape'] != 'Прямой'
    title  = prefix.present? ? "#{prefix} #{product.title}" : product.title
    title  = build_bed_title(adv, title) if product.category == 'Кровати' && adv.extra.present?
    title
  end

  def build_bed_title(adv, title)
    size =
      if adv.extra['sleeping_place_width'] == 160
        'Евро'
      elsif [180, 120].include? adv.extra['sleeping_place_width']
        ''
      else
        adv.extra['sleeping_place_width']
      end
    "#{title} #{size}"
  end
end
