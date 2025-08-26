class IconComponent < ViewComponent::Base
  include ViteRails::TagHelpers

  def initialize(name:, width: 20, height: nil)
    super()
    @name   = name
    @width  = width
    @height = height
  end
end
