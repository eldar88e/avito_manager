class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :ad_imports, dependent: :destroy
  has_many :stores, dependent: :destroy
  has_many :settings, dependent: :destroy
  has_many :ads, dependent: :destroy
  # has_many :products, dependent: :destroy
  # has_many :cache_reports, dependent: :destroy

  after_create :create_default_settings

  def member_of?(store)
    stores.include?(store)
  end

  private

  def create_default_settings
    Setting.transaction do
      default_settings_params.each do |params|
        settings.create!(params.merge(user: self))
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create setting: #{e.message}")
  end

  def default_settings_params
    [
      { variable: 'import_img_size', value: 1080 },
      { variable: 'tg_chat_ids', value: 'example,chat,ids' },
      { variable: 'tg_token', value: 'ExampleBotToken' },
      { variable: 'quantity_games', value: 10 },
      { variable: 'avito_img_width', value: 1920 },
      { variable: 'avito_img_height', value: 1440 },
      { variable: 'avito_back_color', value: '#FFFFFF' }
    ]
  end
end
