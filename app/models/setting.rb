class Setting < ApplicationRecord
  belongs_to :user
  has_one_attached :font, dependent: :purge

  validates :variable, presence: true
  validates :variable, uniqueness: { scope: :user_id }

  after_commit :clear_settings_cache, on: %i[create update destroy]

  def self.all_cached(user_id)
    Rails.cache.fetch("settings/user_#{user_id}") do
      settings = pluck(:variable, :value).to_h.symbolize_keys
      settings[:main_font] = find_by(variable: 'main_font')&.font&.blob
      settings
    end
  end

  def self.fetch_value(key, user_id)
    all_cached(user_id)[key]
  end

  private

  def clear_settings_cache
    Rails.cache.delete("settings/user_#{user_id}")
  end
end
