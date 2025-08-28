class Setting < ApplicationRecord
  belongs_to :user
  has_one_attached :font, dependent: :purge

  validates :variable, presence: true
  validates :variable, uniqueness: { scope: :user_id }

  after_commit :clear_settings_cache, on: %i[create update destroy]

  def self.all_cached
    Rails.cache.fetch(:settings, expires_in: 6.hours) do
      settings             = pluck(:variable, :value).to_h.symbolize_keys
      blob                 = find_by(variable: 'main_font')&.font&.blob
      settings[:main_font] = blob if blob
      settings
    end
  end

  def self.fetch_value(key)
    all_cached[key]
  end

  private

  def clear_settings_cache
    Rails.cache.delete(:settings)
  end
end
