class AdImport < ApplicationRecord
  belongs_to :user

  belongs_to :run
  has_many :ads, as: :adable, dependent: :destroy
  # has_one :game_black_list, primary_key: 'sony_id'

  validates :title, presence: true

  scope :active, -> { where(deleted: false) }
  scope :deleted_not_updated_last_two_months, -> { active.where(updated_at: ...2.months.ago) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[title]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
