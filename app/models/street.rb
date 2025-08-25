class Street < ApplicationRecord
  belongs_to :address

  validates :title, presence: true
  validates :title, uniqueness: { scope: :address_id }
end
