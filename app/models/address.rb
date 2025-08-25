class Address < ApplicationRecord
  validates :city, presence: true

  has_one_attached :image, dependent: :purge
  belongs_to :store
  has_many :streets, dependent: :destroy
  # has_many :ads, dependent: :destroy

  before_validation :check_slogan_params_blank

  scope :active, -> { where(active: true) }

  def store_address
    random_street = streets.sample
    "#{city}, #{random_street.title}" if random_street
  end

  private

  def check_slogan_params_blank
    slogan_params.present? || (self.slogan_params = nil)
  end
end
