class Ad < ApplicationRecord
  validates :file_id, presence: true

  belongs_to :user
  belongs_to :store
  belongs_to :address
  belongs_to :adable, polymorphic: true
  has_one_attached :image, dependent: :purge

  scope :active,        -> { where(deleted: false) }
  scope :not_baned,     -> { where(banned: false).or(where(banned_until: ...Time.current)) }
  scope :active_ads,    -> { not_baned.where(deleted: :active) }
  scope :for_product,   -> { where(adable_type: 'Product') }
  scope :for_ad_import, -> { where(adable_type: 'AdImport') }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id avito_id file_id deleted banned banned_until]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[]
  end
end
