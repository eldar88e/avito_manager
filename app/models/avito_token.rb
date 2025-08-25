class AvitoToken < ApplicationRecord
  belongs_to :store

  validates :access_token, presence: true
  validates :expires_in, presence: true, numericality: { only_integer: true }
  validates :token_type, presence: true

  scope :latest_valid, -> { where('created_at + (expires_in * interval \'1 second\') > ?', Time.current) }
end
