class ImageLayer < ApplicationRecord
  validates :title, presence: true, length: { maximum: 50, minimum: 2 }
  validate :check_img_title, on: %i[update create]

  has_one_attached :layer, dependent: :purge
  belongs_to :store

  enum :layer_type, { img: 0, text: 1 }

  before_save :set_default_menuindex, :set_default_layer_params

  scope :active, -> { where(active: true) }

  private

  def set_default_menuindex
    return if menuindex.present?

    max_menuindex  = ImageLayer.maximum(:menuindex)
    self.menuindex = max_menuindex ? max_menuindex + 1 : 1
  end

  def set_default_layer_params
    layer_params.present? || self.layer_params = nil
  end

  def check_img_title
    errors.add(:base, 'Должна быть указана картинка или текст слоя!') if layer.blank?
  end
end
