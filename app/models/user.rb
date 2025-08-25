class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :ad_imports, dependent: :destroy
  # has_many :stores, dependent: :destroy
  # has_many :settings, dependent: :destroy
  # has_many :products, dependent: :destroy
  # has_many :ads, dependent: :destroy
  # has_many :cache_reports, dependent: :destroy

  after_create :create_default_settings

  def member_of?(store)
    stores.include?(store)
  end

  private

  def create_default_settings
    Setting.transaction do
      default_settings_params.each do |params|
        settings.create!(params)
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create setting: #{e.message}")
  end

  def default_settings_params
    [
      { var: 'game_img_size', value: 1080 },
      { var: 'telegram_chat_id', value: 'example_chat_id' },
      { var: 'telegram_bot_token', value: 'example_bot_token' },
      { var: 'quantity_games', value: 10 },
      { var: 'avito_img_width', value: 1920 },
      { var: 'avito_img_height', value: 1440 },
      { var: 'avito_back_color', value: '#FFFFFF' }
    ]
  end
end
