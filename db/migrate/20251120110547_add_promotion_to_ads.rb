class AddPromotionToAds < ActiveRecord::Migration[8.0]
  def change
    add_column :ads, :promotion, :boolean, default: false, null: false
  end
end
