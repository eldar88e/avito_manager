class DescriptionService
  def initialize(**option)
    @model = option[:model]
    @store = option[:store]
    @default_replacements = {
      name: @model.name,
      description: @store.description,
      manager: @store.manager_name,
      addr_desc: option[:address_desc].to_s
    }
  end

  def make_description
    method_name = :"handle_#{@model.class.name.underscore}_desc"
    send(method_name)
  end

  def self.call(**option)
    new(**option).make_description
  end

  private

  def handle_ad_import_desc
    build_description @store.desc_ad_import.to_s
  end

  def handle_product_desc
    build_description(@store.desc_product.to_s, desc_product: @model.description)
  end

  def build_description(description, **replacements)
    replacements.merge(@default_replacements).each do |key, value|
      description = description.gsub("[#{key}]", value.to_s)
    end
    description.squeeze(' ').strip
  end
end
